import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Dashboard from './pages/Dashboard';
import Login from './pages/Login';

const App: React.FC = () => {
  return (
    <Router>
      <Routes>
        {/*
            The Entrypoint is ALWAYS the Login page.
            There is no top-level loading screen here anymore.
        */}
        <Route path="/" element={<Login />} />
        <Route path="/login" element={<Login />} />

        {/* Dashboard is its own route */}
        <Route path="/dashboard" element={<Dashboard />} />

        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Router>
  );
};

export default App;
