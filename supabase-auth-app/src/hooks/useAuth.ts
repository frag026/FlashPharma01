import { useState, useEffect } from 'react';
import { supabase } from '../supabase/client';

const useAuth = () => {
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(null);

    useEffect(() => {
        const session = supabase.auth.session();
        setUser(session?.user ?? null);
        setLoading(false);

        const { data: subscription } = supabase.auth.onAuthStateChange((_, session) => {
            setUser(session?.user ?? null);
        });

        return () => {
            subscription.unsubscribe();
        };
    }, []);

    const signup = async (email, password) => {
        setLoading(true);
        const { user, error } = await supabase.auth.signUp({ email, password });
        setUser(user);
        setError(error);
        setLoading(false);
    };

    const login = async (email, password) => {
        setLoading(true);
        const { user, error } = await supabase.auth.signIn({ email, password });
        setUser(user);
        setError(error);
        setLoading(false);
    };

    const logout = async () => {
        setLoading(true);
        await supabase.auth.signOut();
        setUser(null);
        setLoading(false);
    };

    return { user, loading, error, signup, login, logout };
};

export default useAuth;