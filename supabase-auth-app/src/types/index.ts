export interface User {
    id: string;
    email: string;
    created_at: string;
}

export interface AuthResponse {
    user: User | null;
    session: {
        access_token: string;
        refresh_token: string;
        expires_in: number;
        token_type: string;
    } | null;
    error: {
        message: string;
    } | null;
}