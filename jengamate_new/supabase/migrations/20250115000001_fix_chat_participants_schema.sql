-- Fix chat_participants table schema to match the expected structure
-- Add missing joined_at column to chat_participants table

-- First, check if the column exists and add it if it doesn't
DO $$ 
BEGIN
    -- Add joined_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'chat_participants' 
        AND column_name = 'joined_at'
    ) THEN
        ALTER TABLE public.chat_participants 
        ADD COLUMN joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        
        -- Update existing records to have a joined_at timestamp
        UPDATE public.chat_participants 
        SET joined_at = NOW() 
        WHERE joined_at IS NULL;
    END IF;
END $$;

-- Add role column if it doesn't exist
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'chat_participants' 
        AND column_name = 'role'
    ) THEN
        ALTER TABLE public.chat_participants 
        ADD COLUMN role TEXT DEFAULT 'member';
    END IF;
END $$;

-- Add id column if it doesn't exist (for consistency with new schema)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'chat_participants' 
        AND column_name = 'id'
    ) THEN
        ALTER TABLE public.chat_participants 
        ADD COLUMN id UUID PRIMARY KEY DEFAULT gen_random_uuid();
    END IF;
END $$;

-- Update the chat_rooms table to match the expected schema
DO $$ 
BEGIN
    -- Add name column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'chat_rooms' 
        AND column_name = 'name'
    ) THEN
        ALTER TABLE public.chat_rooms 
        ADD COLUMN name TEXT;
    END IF;
    
    -- Add type column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'chat_rooms' 
        AND column_name = 'type'
    ) THEN
        ALTER TABLE public.chat_rooms 
        ADD COLUMN type TEXT DEFAULT 'direct';
    END IF;
    
    -- Add created_by column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'chat_rooms' 
        AND column_name = 'created_by'
    ) THEN
        ALTER TABLE public.chat_rooms 
        ADD COLUMN created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL;
    END IF;
    
    -- Add is_active column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'chat_rooms' 
        AND column_name = 'is_active'
    ) THEN
        ALTER TABLE public.chat_rooms 
        ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
    
    -- Add last_message_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'chat_rooms' 
        AND column_name = 'last_message_at'
    ) THEN
        ALTER TABLE public.chat_rooms 
        ADD COLUMN last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- Add updated_at column if it doesn't exist
    IF NOT EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'chat_rooms' 
        AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.chat_rooms 
        ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- Rename messages table to chat_messages if it exists and doesn't match expected schema
DO $$ 
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_name = 'messages' 
        AND table_schema = 'public'
    ) AND NOT EXISTS (
        SELECT 1 
        FROM information_schema.tables 
        WHERE table_name = 'chat_messages' 
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE public.messages RENAME TO chat_messages;
        
        -- Add missing columns to the renamed table
        IF NOT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'chat_messages' 
            AND column_name = 'id'
        ) THEN
            ALTER TABLE public.chat_messages 
            ADD COLUMN id UUID PRIMARY KEY DEFAULT gen_random_uuid();
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'chat_messages' 
            AND column_name = 'message_type'
        ) THEN
            ALTER TABLE public.chat_messages 
            ADD COLUMN message_type TEXT DEFAULT 'text';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'chat_messages' 
            AND column_name = 'metadata'
        ) THEN
            ALTER TABLE public.chat_messages 
            ADD COLUMN metadata JSONB DEFAULT '{}';
        END IF;
        
        IF NOT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'chat_messages' 
            AND column_name = 'is_read'
        ) THEN
            ALTER TABLE public.chat_messages 
            ADD COLUMN is_read BOOLEAN DEFAULT false;
        END IF;
        
        -- Rename timestamp column to created_at if it exists
        IF EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'chat_messages' 
            AND column_name = 'timestamp'
        ) AND NOT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'chat_messages' 
            AND column_name = 'created_at'
        ) THEN
            ALTER TABLE public.chat_messages 
            RENAME COLUMN timestamp TO created_at;
        END IF;
    END IF;
END $$;





