import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Types for our database tables
export interface BetaTest {
    id: string;
    name: string;
    description: string;
    google_groups_link: string;
    playstore_link: string;
    is_active: boolean;
    created_at: string;
}

export interface BetaRegistration {
    id: string;
    test_id: string;
    name: string;
    email: string;
    status: "pending" | "approved" | "rejected";
    created_at: string;
}
