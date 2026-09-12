const SUPABASE_URL = 'https://cguqcmdhiqzijrkyqmuy.supabase.co';
const SUPABASE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNndXFjbWRoaXF6aWpya3lxbXV5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODkwMzU1NTAsImV4cCI6MjEwNDYxMTU1MH0.98lydjM_rhnhFvJxw30WgskuT6a_MLwM8arOioMiW6Q';

// eslint-disable-next-line no-unused-vars -- used as a global by auth.js and script.js
const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY);
