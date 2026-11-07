use anchor_lang::prelude::*;

declare_id!("F3zUFWwbK9pQme2QYtiJcNtwfpFStkKSuAdbuzaqRpML");

pub const MAX_NAME: usize = 40;
pub const MAX_PRODUCT: usize = 48;
pub const MAX_ORIGIN: usize = 48;
pub const MAX_REASON: usize = 80;
pub const MAX_QUANTITY: u32 = 100_000;

/// Authentic registry.
///
/// Producers sign tags off-chain with an Ed25519 key. The key is registered
/// here so anyone can check that a tag's signer is a known producer, and that
/// the tag's batch exists and has not been recalled. Writes go through the
/// registry admin (the relayer), which checks the producer's signed request
/// before submitting.
#[program]
pub mod authentic {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>) -> Result<()> {
        let registry = &mut ctx.accounts.registry;
        registry.admin = ctx.accounts.admin.key();
        registry.bump = ctx.bumps.registry;
        Ok(())
    }

    pub fn register_producer(
        ctx: Context<RegisterProducer>,
        producer_key: Pubkey,
        name: String,
    ) -> Result<()> {
        require!(!name.trim().is_empty(), AuthenticError::EmptyField);
        require!(name.len() <= MAX_NAME, AuthenticError::TextTooLong);

        let producer = &mut ctx.accounts.producer;
        producer.key = producer_key;
        producer.name = name.clone();
        producer.registered_at = Clock::get()?.unix_timestamp;
        producer.active = true;
        producer.bump = ctx.bumps.producer;

        emit!(ProducerRegistered {
            producer: producer_key,
            name,
        });
        Ok(())
    }

    pub fn create_batch(
        ctx: Context<CreateBatch>,
        batch_id: u64,
        product_name: String,
        origin: String,
        quantity: u32,
    ) -> Result<()> {
        require!(ctx.accounts.producer.active, AuthenticError::ProducerInactive);
        require!(
            !product_name.trim().is_empty() && !origin.trim().is_empty(),
            AuthenticError::EmptyField
        );
        require!(
            product_name.len() <= MAX_PRODUCT && origin.len() <= MAX_ORIGIN,
            AuthenticError::TextTooLong
        );
        require!(
            quantity > 0 && quantity <= MAX_QUANTITY,
            AuthenticError::BadQuantity
        );

        let batch = &mut ctx.accounts.batch;
        batch.producer = ctx.accounts.producer.key;
        batch.batch_id = batch_id;
        batch.product_name = product_name;
        batch.origin = origin;
        batch.quantity = quantity;
        batch.created_at = Clock::get()?.unix_timestamp;
        batch.recalled = false;
        batch.recalled_at = 0;
        batch.recall_reason = String::new();
        batch.bump = ctx.bumps.batch;

        emit!(BatchCreated {
            producer: batch.producer,
            batch_id,
            quantity,
        });
        Ok(())
    }

    pub fn recall_batch(ctx: Context<RecallBatch>, reason: String) -> Result<()> {
        require!(!reason.trim().is_empty(), AuthenticError::EmptyField);
        require!(reason.len() <= MAX_REASON, AuthenticError::TextTooLong);

        let batch = &mut ctx.accounts.batch;
        require!(!batch.recalled, AuthenticError::AlreadyRecalled);
        batch.recalled = true;
        batch.recalled_at = Clock::get()?.unix_timestamp;
        batch.recall_reason = reason;

        emit!(BatchRecalled {
            producer: batch.producer,
            batch_id: batch.batch_id,
        });
        Ok(())
    }
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,
        payer = admin,
        space = 8 + Registry::INIT_SPACE,
        seeds = [b"registry"],
        bump
    )]
    pub registry: Account<'info, Registry>,
    #[account(mut)]
    pub admin: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(producer_key: Pubkey)]
pub struct RegisterProducer<'info> {
    #[account(seeds = [b"registry"], bump = registry.bump, has_one = admin)]
    pub registry: Account<'info, Registry>,
    #[account(
        init,
        payer = admin,
        space = 8 + Producer::INIT_SPACE,
        seeds = [b"producer", producer_key.as_ref()],
        bump
    )]
    pub producer: Account<'info, Producer>,
    #[account(mut)]
    pub admin: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
#[instruction(batch_id: u64)]
pub struct CreateBatch<'info> {
    #[account(seeds = [b"registry"], bump = registry.bump, has_one = admin)]
    pub registry: Account<'info, Registry>,
    #[account(
        seeds = [b"producer", producer.key.as_ref()],
        bump = producer.bump
    )]
    pub producer: Account<'info, Producer>,
    #[account(
        init,
        payer = admin,
        space = 8 + Batch::INIT_SPACE,
        seeds = [b"batch", producer.key.as_ref(), &batch_id.to_le_bytes()],
        bump
    )]
    pub batch: Account<'info, Batch>,
    #[account(mut)]
    pub admin: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct RecallBatch<'info> {
    #[account(seeds = [b"registry"], bump = registry.bump, has_one = admin)]
    pub registry: Account<'info, Registry>,
    #[account(
        mut,
        seeds = [b"batch", batch.producer.as_ref(), &batch.batch_id.to_le_bytes()],
        bump = batch.bump
    )]
    pub batch: Account<'info, Batch>,
    pub admin: Signer<'info>,
}

#[account]
#[derive(InitSpace)]
pub struct Registry {
    pub admin: Pubkey,
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct Producer {
    pub key: Pubkey,
    #[max_len(MAX_NAME)]
    pub name: String,
    pub registered_at: i64,
    pub active: bool,
    pub bump: u8,
}

#[account]
#[derive(InitSpace)]
pub struct Batch {
    pub producer: Pubkey,
    pub batch_id: u64,
    #[max_len(MAX_PRODUCT)]
    pub product_name: String,
    #[max_len(MAX_ORIGIN)]
    pub origin: String,
    pub quantity: u32,
    pub created_at: i64,
    pub recalled: bool,
    pub recalled_at: i64,
    #[max_len(MAX_REASON)]
    pub recall_reason: String,
    pub bump: u8,
}

#[event]
pub struct ProducerRegistered {
    pub producer: Pubkey,
    pub name: String,
}

#[event]
pub struct BatchCreated {
    pub producer: Pubkey,
    pub batch_id: u64,
    pub quantity: u32,
}

#[event]
pub struct BatchRecalled {
    pub producer: Pubkey,
    pub batch_id: u64,
}

#[error_code]
pub enum AuthenticError {
    #[msg("A required field is empty")]
    EmptyField,
    #[msg("Text is too long")]
    TextTooLong,
    #[msg("Quantity must be between 1 and 100000")]
    BadQuantity,
    #[msg("Producer is not active")]
    ProducerInactive,
    #[msg("Batch is already recalled")]
    AlreadyRecalled,
}
