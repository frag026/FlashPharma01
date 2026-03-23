import React, { useState } from 'react';
import { useAuth } from '../hooks/useAuth';
import AuthForm from '../components/AuthForm';

const LoginScreen: React.FC = () => {
    const { login } = useAuth();
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');

    const handleLogin = async (event: React.FormEvent) => {
        event.preventDefault();
        setError('');

        try {
            await login(email, password);
        } catch (err) {
            setError('Failed to log in. Please check your credentials.');
        }
    };

    return (
        <div>
            <h2>Login</h2>
            <AuthForm
                email={email}
                setEmail={setEmail}
                password={password}
                setPassword={setPassword}
                onSubmit={handleLogin}
                error={error}
                buttonText="Login"
            />
        </div>
    );
};

export default LoginScreen;