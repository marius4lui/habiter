import { createClient } from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL!;
const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!;

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

// Types for our database tables
export interface BetaTest {
    id: string;
    name: string;
    description: string;
    tester_method: "google_groups" | "csv";
    google_groups_link: string | null;
    playstore_link: string;
    is_active: boolean;
    priority: number; // 0=Stable, 1=Beta, 2=Alpha, 3=Nightly
    created_at: string;
}

export interface BetaRegistration {
    id: string;
    test_id: string;
    first_name: string;
    last_name: string;
    email: string;
    status: "pending" | "approved" | "rejected";
    created_at: string;
}
