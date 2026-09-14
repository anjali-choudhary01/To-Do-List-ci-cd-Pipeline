def pushStageMetric(String stageName, String status) {
    catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
        bat """
            powershell -NoProfile -ExecutionPolicy Bypass ^
            -File scripts\\push-stage-metrics.ps1 ^
            -Stage "${stageName}" ^
            -Status "${status}"
        """
    }
}

pipeline {
    agent any

    options {
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '20'))
    }

    tools {
        nodejs 'node'
    }

    stages {

        stage('Checkout') {
            steps {
                script {
                    // Initialize all CI/CD stage metrics
                    pushStageMetric('Pipeline', 'INIT')
                }

                git branch: 'main',
                    url: 'https://github.com/anjali-choudhary01/To-Do-List-ci-cd-Pipeline.git'
            }

            post {
                success {
                    pushStageMetric('Checkout', 'SUCCESS')
                }
                unstable {
                    pushStageMetric('Checkout', 'UNSTABLE')
                }
                failure {
                    pushStageMetric('Checkout', 'FAILURE')
                }
            }
        }

        stage('Install') {
            steps {
                bat 'npm install'
            }

            post {
                success {
                    pushStageMetric('Install', 'SUCCESS')
                }
                unstable {
                    pushStageMetric('Install', 'UNSTABLE')
                }
                failure {
                    pushStageMetric('Install', 'FAILURE')
                }
            }
        }

        stage('Lint') {
            steps {
                bat 'npm run lint'
            }

            post {
                success {
                    pushStageMetric('Lint', 'SUCCESS')
                }
                unstable {
                    pushStageMetric('Lint', 'UNSTABLE')
                }
                failure {
                    pushStageMetric('Lint', 'FAILURE')
                }
            }
        }

        stage('Test') {
            steps {
                bat 'npm test'
            }

            post {
                success {
                    pushStageMetric('Test', 'SUCCESS')
                }
                unstable {
                    pushStageMetric('Test', 'UNSTABLE')
                }
                failure {
                    pushStageMetric('Test', 'FAILURE')
                }
            }
        }

        stage('Security Scan - Trivy') {
            steps {

                bat '''
                    trivy fs --include-dev-deps ^
                      --format json ^
                      --output trivy-report.json .
                '''

                catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                    bat '''
                        powershell -NoProfile -ExecutionPolicy Bypass ^
                        -File scripts\\push-trivy-metrics.ps1
                    '''
                }

                bat '''
                    trivy fs --include-dev-deps ^
                      --format template ^
                      --template "@scripts/trivy-html.tpl" ^
                      -o trivy-report.html .
                '''

                archiveArtifacts artifacts: 'trivy-report.html,trivy-report.json',
                    allowEmptyArchive: true,
                    fingerprint: true

                bat '''
                    trivy fs --include-dev-deps ^
                      --exit-code 1 ^
                      --severity HIGH,CRITICAL .
                '''
            }

            post {
                success {
                    pushStageMetric('Security Scan - Trivy', 'SUCCESS')
                }
                unstable {
                    pushStageMetric('Security Scan - Trivy', 'UNSTABLE')
                }
                failure {
                    pushStageMetric('Security Scan - Trivy', 'FAILURE')
                }
            }
        }

        stage('SonarCloud Analysis') {
            steps {
                script {
                    def scannerHome = tool 'SonarScanner'

                    withSonarQubeEnv('SonarQube Cloud') {
                        bat "\"${scannerHome}\\bin\\sonar-scanner.bat\" -Dsonar.organization=anjali-choudhary01 -Dsonar.projectKey=anjali-choudhary01_To-Do-List-ci-cd-Pipeline -Dsonar.sources=. -Dsonar.exclusions=**/node_modules/**,**/coverage/**,**/*.test.js -Dsonar.tests=. -Dsonar.test.inclusions=**/*.test.js -Dsonar.javascript.lcov.reportPaths=coverage/lcov.info"
                    }
                }
            }

            post {
                success {
                    pushStageMetric('SonarCloud Analysis', 'SUCCESS')
                }
                unstable {
                    pushStageMetric('SonarCloud Analysis', 'UNSTABLE')
                }
                failure {
                    pushStageMetric('SonarCloud Analysis', 'FAILURE')
                }
            }
        }

        stage('Docker Build') {
            steps {
                bat 'docker build -t to-do-list-app:%BUILD_NUMBER% .'
            }

            post {
                success {
                    pushStageMetric('Docker Build', 'SUCCESS')
                }
                unstable {
                    pushStageMetric('Docker Build', 'UNSTABLE')
                }
                failure {
                    pushStageMetric('Docker Build', 'FAILURE')
                }
            }
        }

        stage('Archive Application') {
            steps {
                bat '''
                    powershell -NoProfile -Command ^
                    "Compress-Archive -Path index.html,todo.html,auth.js,auth.css,supabaseClient.js,script.js,style.css,images -DestinationPath to-do-list.zip -Force"
                '''

                archiveArtifacts artifacts: 'to-do-list.zip',
                    fingerprint: true
            }

            post {
                success {
                    pushStageMetric('Archive Application', 'SUCCESS')
                }
                unstable {
                    pushStageMetric('Archive Application', 'UNSTABLE')
                }
                failure {
                    pushStageMetric('Archive Application', 'FAILURE')
                }
            }
        }

        stage('Deploy to Vercel') {
            steps {
                withCredentials([
                    string(
                        credentialsId: 'vercel-api-token',
                        variable: 'VERCEL_TOKEN'
                    )
                ]) {
                    withEnv([
                        'VERCEL_ORG_ID=team_lIUUBohaz6LvLVQOhv3iZUs8',
                        'VERCEL_PROJECT_ID=prj_5ERx4TQpdiFEeBBUjyfs30ul84eZ'
                    ]) {
                        bat 'npx --yes vercel --prod --token=%VERCEL_TOKEN% --yes'
                    }
                }
            }

            post {
                success {
                    pushStageMetric('Deploy to Vercel', 'SUCCESS')
                }
                unstable {
                    pushStageMetric('Deploy to Vercel', 'UNSTABLE')
                }
                failure {
                    pushStageMetric('Deploy to Vercel', 'FAILURE')
                }
            }
        }

        stage('OWASP ZAP Scan') {
            steps {
                script {
                    def zapExitCode = bat(
                        script: '''
                            docker run -t ^
                            -v "%WORKSPACE%:/zap/wrk/:rw" ^
                            zaproxy/zap-stable ^
                            zap-baseline.py ^
                            -t https://to-do-list-ci-cd-pipeline.vercel.app ^
                            -r zap-report.html ^
                            -J zap-report.json ^
                            -x zap-report.xml
                        ''',
                        returnStatus: true
                    )

                    echo "ZAP exit code: ${zapExitCode}"

                    if (zapExitCode != 0) {
                        echo "ZAP completed with warnings/non-zero exit code. Build will continue."
                    }

                    catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                        bat '''
                            powershell -NoProfile -ExecutionPolicy Bypass ^
                            -File scripts\\push-zap-metrics.ps1
                        '''
                    }
                }

                archiveArtifacts artifacts: 'zap-report.html,zap-report.json,zap-report.xml',
                    allowEmptyArchive: true,
                    fingerprint: true
            }

            post {
                success {
                    pushStageMetric('OWASP ZAP Scan', 'SUCCESS')
                }
                unstable {
                    pushStageMetric('OWASP ZAP Scan', 'UNSTABLE')
                }
                failure {
                    pushStageMetric('OWASP ZAP Scan', 'FAILURE')
                }
            }
        }

        stage('DefectDojo - Trivy') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    withCredentials([
                        string(
                            credentialsId: 'defectdojo-api-key',
                            variable: 'DEFECTDOJO_API_KEY'
                        )
                    ]) {
                        bat '''
                            echo.
                            echo ==========================================
                            echo Uploading Trivy Report to DefectDojo
                            echo ==========================================

                            if not exist trivy-report.json (
                                echo WARNING: trivy-report.json not found
                                exit /b 0
                            )

                            curl.exe -sS ^
                              -X POST ^
                              "http://localhost:8082/api/v2/reimport-scan/" ^
                              -H "Authorization: Token %DEFECTDOJO_API_KEY%" ^
                              -F "product_type_name=Research and Development" ^
                              -F "product_name=To-Do-List" ^
                              -F "engagement_name=Trivy-ZAP-Scan-01" ^
                              -F "auto_create_context=true" ^
                              -F "scan_type=Trivy Scan" ^
                              -F "test_title=Trivy Security Scan" ^
                              -F "file=@trivy-report.json"

                            if errorlevel 1 (
                                echo WARNING: Trivy upload to DefectDojo failed.
                                exit /b 0
                            )

                            echo Trivy report uploaded successfully.
                        '''
                    }
                }
            }

            post {
                success {
                    pushStageMetric('DefectDojo - Trivy', 'SUCCESS')
                }
                unstable {
                    pushStageMetric('DefectDojo - Trivy', 'UNSTABLE')
                }
                failure {
                    pushStageMetric('DefectDojo - Trivy', 'FAILURE')
                }
            }
        }

        stage('DefectDojo - ZAP') {
            steps {
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    withCredentials([
                        string(
                            credentialsId: 'defectdojo-api-key',
                            variable: 'DEFECTDOJO_API_KEY'
                        )
                    ]) {
                        bat '''
                            echo.
                            echo ==========================================
                            echo Uploading ZAP XML Report to DefectDojo
                            echo ==========================================

                            if not exist zap-report.xml (
                                echo WARNING: zap-report.xml not found.
                                exit /b 0
                            )

                            echo ZAP XML found:
                            dir zap-report.xml

                            curl.exe -sS ^
                              -X POST ^
                              "http://localhost:8082/api/v2/reimport-scan/" ^
                              -H "Authorization: Token %DEFECTDOJO_API_KEY%" ^
                              -F "product_type_name=Research and Development" ^
                              -F "product_name=To-Do-List" ^
                              -F "engagement_name=Trivy-ZAP-Scan-01" ^
                              -F "auto_create_context=true" ^
                              -F "scan_type=ZAP Scan" ^
                              -F "test_title=OWASP ZAP Security Scan" ^
                              -F "file=@zap-report.xml"

                            if errorlevel 1 (
                                echo WARNING: ZAP upload to DefectDojo failed.
                                exit /b 0
                            )

                            echo ZAP XML report uploaded successfully.
                        '''
                    }
                }
            }

            post {
                success {
                    pushStageMetric('DefectDojo - ZAP', 'SUCCESS')
                }
                unstable {
                    pushStageMetric('DefectDojo - ZAP', 'UNSTABLE')
                }
                failure {
                    pushStageMetric('DefectDojo - ZAP', 'FAILURE')
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline completed. Cleaning workspace."
            cleanWs()
        }

        success {
            mail to: 'anjalichoudhary8844@gmail.com',
                 subject: "✅ Build Success: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: "Build successful!\n\nCheck details: ${env.BUILD_URL}"
        }

        failure {
            mail to: 'anjalichoudhary8844@gmail.com',
                 subject: "❌ Build Failed: ${env.JOB_NAME} #${env.BUILD_NUMBER}",
                 body: "Build failed!\n\nCheck details: ${env.BUILD_URL}"
        }
    }
}