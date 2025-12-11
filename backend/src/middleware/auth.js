import { supabase } from '../lib/supabase.js';

/**
 * Middleware to verify Supabase JWT token
 * Sets req.user with authenticated user information
 */
export async function authMiddleware(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Missing or invalid authorization header' });
    }

    const token = authHeader.substring(7);
    
    if (supabase) {
      const { data: { user }, error } = await supabase.auth.getUser(token);

      if (error || !user) {
        return res.status(401).json({ error: 'Invalid or expired token' });
      }

      req.user = user;
      req.accessToken = token;
    } else {
      // Mock user for demo
      req.user = {
        id: 'mock-user-id',
        email: 'demo@zenbase.online'
      };
      req.accessToken = token;
    }
    
    next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
}

/**
 * Optional auth middleware - continues even if no valid token
 */
export async function optionalAuthMiddleware(req, res, next) {
  try {
    const authHeader = req.headers.authorization;
    
    if (authHeader && authHeader.startsWith('Bearer ')) {
      const token = authHeader.substring(7);
      
      if (supabase) {
        const { data: { user } } = await supabase.auth.getUser(token);
        
        if (user) {
          req.user = user;
          req.accessToken = token;
        }
      } else {
        // Mock user for demo
        req.user = {
          id: 'mock-user-id',
          email: 'demo@zenbase.online'
        };
        req.accessToken = token;
      }
    }
    
    next();
  } catch (error) {
    console.error('Optional auth middleware error:', error);
    next();
  }
}
