import { supabase } from '../lib/supabase.js';

export class AuthService {
    /**
     * Verify a Supabase JWT token
     * @param {string} token 
     * @returns {Promise<{user: object|null, error: object|null}>}
     */
    static async verifyToken(token) {
        if (!token) return { user: null, error: { message: 'Token required' } };

        const { data: { user }, error } = await supabase.auth.getUser(token);

        if (error || !user) {
            return { user: null, error: error || { message: 'Invalid token' } };
        }

        return { user, error: null };
    }
}
