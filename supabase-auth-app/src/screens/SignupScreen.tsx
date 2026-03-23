import React, { useState } from 'react';
import { supabase } from '../supabase/client';
import AuthForm from '../components/AuthForm';

const SignupScreen = () => {
    const [error, setError] = useState(null);

    const handleSignup = async (email, password) => {
        const { user, error } = await supabase.auth.signUp({
            email,
            password,
        });

        if (error) {
            setError(error.message);
        } else {
            setError(null);
            // Handle successful signup (e.g., redirect or show a success message)
        }
    };

    return (
        <div>
            <h1>Sign Up</h1>
            {error && <p style={{ color: 'red' }}>{error}</p>}
            <AuthForm onSubmit={handleSignup} />
        </div>
    );
};

export default SignupScreen;