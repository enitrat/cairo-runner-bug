use starknet::ContractAddress;

#[abi]
trait IVault {
    /// IERC20 functions
    fn name() -> felt252;
    fn symbol() -> felt252;
    fn decimals() -> u8;
    fn total_supply() -> u256;
    fn balance_of(account: ContractAddress) -> u256;
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256;
    fn transfer(recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
    fn approve(spender: ContractAddress, amount: u256) -> bool;
    /// ERC4626-specific functions
    fn asset() -> ContractAddress;
    fn total_assets() -> u256;
    fn convert_to_shares(assets: u256) -> u256;
    fn convert_to_assets(shares: u256) -> u256;
    fn max_deposit(amount: u256) -> u256;
    fn preview_deposit(assets: u256) -> u256;
    fn deposit(assets: u256, receiver: ContractAddress) -> u256;
    fn max_mint(receiver: ContractAddress) -> u256;
    fn preview_mint(shares: u256) -> u256;
    fn mint(shares: u256, receiver: ContractAddress, ) -> u256;
    fn max_withdraw(owner: ContractAddress) -> u256;
    fn preview_withdraw(assets: u256) -> u256;
    fn withdraw(assets: u256, receiver: ContractAddress, owner: ContractAddress) -> u256;
    fn max_redeem(owner: ContractAddress) -> u256;
    fn preview_redeem(shares: u256) -> u256;
    fn redeem(shares: u256, receiver: ContractAddress, owner: ContractAddress) -> u256;
    // Vault-specific functions
    fn total_float() -> u256;
}
#[contract]
mod Vault {
    use super::IVault;
    use simple_vault::erc4626::ERC4626;
    use simple_vault::strategy::{IStrategyDispatcher, IStrategyDispatcherTrait};
    use openzeppelin::token::erc20::{ERC20, IERC20Dispatcher, IERC20DispatcherTrait};
    use traits::Into;
    use starknet::ContractAddress;
    use starknet::{get_caller_address, get_contract_address};
    use option::OptionTrait;

    struct Storage {
        _strategy: IStrategyDispatcher
    }

    impl Vault of IVault {
        fn name() -> felt252 {
            ERC20::name()
        }


        fn symbol() -> felt252 {
            ERC20::symbol()
        }


        fn decimals() -> u8 {
            ERC20::decimals()
        }


        fn total_supply() -> u256 {
            ERC20::total_supply()
        }


        fn balance_of(account: ContractAddress) -> u256 {
            ERC20::balance_of(account)
        }


        fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256 {
            ERC20::allowance(owner, spender)
        }


        fn transfer(recipient: ContractAddress, amount: u256) -> bool {
            ERC20::transfer(recipient, amount)
        }


        fn transfer_from(
            sender: ContractAddress, recipient: ContractAddress, amount: u256
        ) -> bool {
            ERC20::transfer_from(sender, recipient, amount)
        }


        fn approve(spender: ContractAddress, amount: u256) -> bool {
            ERC20::approve(spender, amount)
        }


        // fn increase_allowance(spender: ContractAddress, added_value: u256) -> bool {
        //     ERC20::_increase_allowance(spender, added_value)
        // }

        // fn decrease_allowance(spender: ContractAddress, subtracted_value: u256) -> bool {
        //     ERC20::_decrease_allowance(spender, subtracted_value)
        // }
        ////////////////////////////////////////////////////////////////
        // ERC4626 functions
        ////////////////////////////////////////////////////////////////

        fn asset() -> ContractAddress {
            ERC4626::asset()
        }

        fn total_assets() -> u256 {
            ERC4626::total_assets()
        }

        fn convert_to_shares(assets: u256) -> u256 {
            ERC4626::convert_to_shares(assets)
        }

        fn convert_to_assets(shares: u256) -> u256 {
            ERC4626::convert_to_assets(shares)
        }

        fn max_deposit(amount: u256) -> u256 {
            ERC4626::max_deposit(amount)
        }

        fn preview_deposit(assets: u256) -> u256 {
            ERC4626::preview_deposit(assets)
        }

        fn deposit(assets: u256, receiver: ContractAddress) -> u256 {
            ERC4626::deposit(assets, receiver)
        }

        fn max_mint(receiver: ContractAddress) -> u256 {
            ERC4626::max_mint(receiver)
        }

        fn preview_mint(shares: u256) -> u256 {
            ERC4626::preview_mint(shares)
        }

        fn mint(shares: u256, receiver: ContractAddress) -> u256 {
            ERC4626::mint(shares, receiver)
        }

        fn max_withdraw(owner: ContractAddress) -> u256 {
            ERC4626::max_withdraw(owner)
        }

        fn preview_withdraw(assets: u256) -> u256 {
            ERC4626::preview_withdraw(assets)
        }

        fn withdraw(assets: u256, receiver: ContractAddress, owner: ContractAddress) -> u256 {
            _retrieve_underlying(assets);
            ERC4626::withdraw(assets, receiver, owner)
        }

        fn max_redeem(owner: ContractAddress) -> u256 {
            ERC4626::max_redeem(owner)
        }

        fn preview_redeem(shares: u256) -> u256 {
            ERC4626::preview_redeem(shares)
        }

        fn redeem(shares: u256, receiver: ContractAddress, owner: ContractAddress) -> u256 {
            ERC4626::redeem(shares, receiver, owner)
        }

        ////////////////////////////////////////////////////////////////
        // Vault-specific functions
        ////////////////////////////////////////////////////////////////

        // idle tokens in vault
        fn total_float() -> u256 {
            let token = ERC4626::_asset::read();
            token.balance_of(get_contract_address())
        }
    // fn harvest() -> u256 {
    //     //TODO
    //     1.into()
    // }
    }


    ////////////////////////////////////////////////////////////////
    // ENTRYPOINTS
    ////////////////////////////////////////////////////////////////

    #[constructor]
    fn constructor(name: felt252, symbol: felt252, asset: ContractAddress) {
        ERC4626::initializer(name, symbol, asset);
    }

    ////////////////////////////////
    // ERC20 entrypoints
    ////////////////////////////////

    #[view]
    fn name() -> felt252 {
        Vault::name()
    }

    #[view]
    fn symbol() -> felt252 {
        Vault::symbol()
    }

    #[view]
    fn decimals() -> u8 {
        Vault::decimals()
    }

    #[view]
    fn total_supply() -> u256 {
        Vault::total_supply()
    }

    #[view]
    fn balance_of(account: ContractAddress) -> u256 {
        Vault::balance_of(account)
    }

    #[view]
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256 {
        Vault::allowance(owner, spender)
    }

    #[external]
    fn transfer(recipient: ContractAddress, amount: u256) -> bool {
        Vault::transfer(recipient, amount)
    }

    #[external]
    fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool {
        Vault::transfer_from(sender, recipient, amount)
    }

    #[external]
    fn approve(spender: ContractAddress, amount: u256) -> bool {
        Vault::approve(spender, amount)
    }

    // #[external]
    // fn increase_allowance(spender: ContractAddress, added_value: u256) -> bool {
    //     ERC20::_increase_allowance(spender, added_value)
    // }

    // #[external]
    // fn decrease_allowance(spender: ContractAddress, subtracted_value: u256) -> bool {
    //     ERC20::_decrease_allowance(spender, subtracted_value)
    // }

    ////////////////////////////////////////////////////////////////
    // ERC4626 functions
    ////////////////////////////////////////////////////////////////

    #[view]
    fn asset() -> ContractAddress {
        Vault::asset()
    }

    #[view]
    fn total_assets() -> u256 {
        Vault::total_assets()
    }

    #[view]
    fn convert_to_shares(assets: u256) -> u256 {
        Vault::convert_to_shares(assets)
    }

    #[view]
    fn convert_to_assets(shares: u256) -> u256 {
        Vault::convert_to_assets(shares)
    }

    #[view]
    fn max_deposit(amount: u256) -> u256 {
        Vault::max_deposit(amount)
    }

    #[view]
    fn preview_deposit(assets: u256) -> u256 {
        Vault::preview_deposit(assets)
    }

    #[external]
    fn deposit(assets: u256, receiver: ContractAddress) -> u256 {
        Vault::deposit(assets, receiver)
    }

    #[view]
    fn max_mint(receiver: ContractAddress) -> u256 {
        Vault::max_mint(receiver)
    }

    #[view]
    fn preview_mint(shares: u256) -> u256 {
        Vault::preview_mint(shares)
    }

    #[external]
    fn mint(shares: u256, receiver: ContractAddress) -> u256 {
        Vault::mint(shares, receiver)
    }

    #[view]
    fn max_withdraw(owner: ContractAddress) -> u256 {
        Vault::max_withdraw(owner)
    }

    #[view]
    fn preview_withdraw(assets: u256) -> u256 {
        Vault::preview_withdraw(assets)
    }

    #[external]
    fn withdraw(assets: u256, receiver: ContractAddress, owner: ContractAddress) -> u256 {
        Vault::withdraw(assets, receiver, owner)
    }

    #[view]
    fn max_redeem(owner: ContractAddress) -> u256 {
        Vault::max_redeem(owner)
    }

    #[view]
    fn preview_redeem(shares: u256) -> u256 {
        Vault::preview_redeem(shares)
    }

    #[external]
    fn redeem(shares: u256, receiver: ContractAddress, owner: ContractAddress) -> u256 {
        Vault::redeem(shares, receiver, owner)
    }

    ////////////////////////////////
    // Vault-specific entrypoints
    ////////////////////////////////

    #[external]
    fn total_float() -> u256 {
        Vault::total_float()
    }

    ////////////////////////////////////////////////////////////////
    // Internal functions
    ////////////////////////////////////////////////////////////////

    // simple function that retrieves underlying assets from the vault's strategies.
    // For now, the vault only supports one strategy that is stored in a storage var
    fn _retrieve_underlying(underlying_amount: u256) {
        let float = IVault::total_float();

        if float < underlying_amount {
            //TODO should use WadMath here
            let float_missing_for_withdrawal = underlying_amount - float;
            let strategy = _strategy::read();
            strategy.withdraw(float_missing_for_withdrawal);
        }
    }
}
