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
                git branch: 'main',
                    url: 'https://github.com/anjali-choudhary01/To-Do-List-ci-cd-Pipeline.git'
            }
        }

        stage('Install') {
            steps {
                bat 'npm install'
            }
        }

        stage('Lint') {
            steps {
                bat 'npm run lint'
            }
        }

        stage('Test') {
            steps {
                bat 'npm test'
            }
        }

        stage('Security Scan') {
            steps {

                catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {

                    bat 'trivy fs --include-dev-deps --format json --output trivy-report.json .'

                    bat 'powershell -NoProfile -ExecutionPolicy Bypass -File scripts\\push-trivy-metrics.ps1'

                    bat 'trivy fs --include-dev-deps --format template --template "@scripts/trivy-html.tpl" -o trivy-report.html .'
                }

                archiveArtifacts artifacts: 'trivy-report.html',
                    allowEmptyArchive: true,
                    fingerprint: true

                bat 'trivy fs --include-dev-deps --exit-code 1 --severity HIGH,CRITICAL .'
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
        }

        stage('Docker Build') {
            steps {
                bat 'docker build -t to-do-list-app:%BUILD_NUMBER% .'
            }
        }

        stage('Archive') {
            steps {

                bat 'powershell -NoProfile -Command "Compress-Archive -Path index.html,todo.html,auth.js,auth.css,supabaseClient.js,script.js,style.css,images -DestinationPath to-do-list.zip -Force"'

                archiveArtifacts artifacts: 'to-do-list.zip',
                    fingerprint: true
            }
        }

        stage('Deploy') {
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
        }

        stage('OWASP ZAP Scan') {
            steps {
                script {

                    def zapExitCode = bat(
                        script: 'docker run -t -v "%WORKSPACE%:/zap/wrk/:rw" zaproxy/zap-stable zap-baseline.py -t https://to-do-list-ci-cd-pipeline.vercel.app -r zap-report.html -J zap-report.json',
                        returnStatus: true
                    )

                    if (zapExitCode != 0) {

                        echo "ZAP baseline scan completed with exit code ${zapExitCode}. Review zap-report.html for warnings."
                    }

                    catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {

                        bat 'powershell -NoProfile -ExecutionPolicy Bypass -File scripts\\push-zap-metrics.ps1'
                    }
                }

                archiveArtifacts artifacts: 'zap-report.html',
                    allowEmptyArchive: true,
                    fingerprint: true
            }
        }

        /*
         * ============================================================
         * DEFECTDOJO INTEGRATION
         * ============================================================
         */

        stage('DefectDojo - Trivy') {
            steps {

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
                            echo ERROR: trivy-report.json not found
                            exit /b 1
                        )

                        curl.exe -sS -f ^
                          -X POST "http://localhost:8082/api/v2/reimport-scan/" ^
                          -H "Authorization: Token %DEFECTDOJO_API_KEY%" ^
                          -F "product_type_name=Research and Development" ^
                          -F "product_name=To-Do-List" ^
                          -F "engagement_name=Trivy-ZAP-Scan-01" ^
                          -F "auto_create_context=true" ^
                          -F "scan_type=Trivy Scan" ^
                          -F "test_title=Trivy Security Scan" ^
                          -F "file=@trivy-report.json"

                        if errorlevel 1 (
                            echo ERROR: Trivy upload to DefectDojo failed
                            exit /b 1
                        )

                        echo Trivy report uploaded successfully to DefectDojo.
                    '''
                }
            }
        }

        stage('DefectDojo - ZAP') {
            steps {

                withCredentials([
                    string(
                        credentialsId: 'defectdojo-api-key',
                        variable: 'DEFECTDOJO_API_KEY'
                    )
                ]) {

                    bat '''
                        echo.
                        echo ==========================================
                        echo Uploading ZAP Report to DefectDojo
                        echo ==========================================

                        if not exist zap-report.json (
                            echo ERROR: zap-report.json not found
                            exit /b 1
                        )

                        curl.exe -sS -f ^
                          -X POST "http://localhost:8082/api/v2/reimport-scan/" ^
                          -H "Authorization: Token %DEFECTDOJO_API_KEY%" ^
                          -F "product_type_name=Research and Development" ^
                          -F "product_name=To-Do-List" ^
                          -F "engagement_name=Trivy-ZAP-Scan-01" ^
                          -F "auto_create_context=true" ^
                          -F "scan_type=ZAP Scan" ^
                          -F "test_title=OWASP ZAP Security Scan" ^
                          -F "file=@zap-report.json"

                        if errorlevel 1 (
                            echo ERROR: ZAP upload to DefectDojo failed
                            exit /b 1
                        )

                        echo ZAP report uploaded successfully to DefectDojo.
                    '''
                }
            }
        }
    }

    post {

        always {
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