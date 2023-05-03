// OpenZeppelin ERC20 Cairo Contract;

use starknet::ContractAddress;

#[abi]
trait IERC4626 {
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
}

#[contract]
mod ERC4626 {
    use super::IERC4626;
    use openzeppelin::token::erc20::IERC20Dispatcher;
    use openzeppelin::token::erc20::IERC20DispatcherTrait;
    use starknet::get_caller_address;
    use starknet::get_contract_address;
    use starknet::ContractAddress;
    use starknet::contract_address::ContractAddressZeroable;
    use zeroable::Zeroable;
    use traits::Into;
    use traits::TryInto;
    use option::OptionTrait;
    use integer::BoundedInt;
    use debug::PrintTrait;


    struct Storage {
        _name: felt252,
        _symbol: felt252,
        _total_supply: u256,
        _balances: LegacyMap<ContractAddress, u256>,
        _allowances: LegacyMap<(ContractAddress, ContractAddress), u256>,
        _asset: IERC20Dispatcher
    }

    //TODO move this outside
    trait MathRounding {
        fn div_up(self: u256, rhs: u256) -> u256;
    }

    impl MathRoundingImpl of MathRounding {
        fn div_up(self: u256, rhs: u256) -> u256 {
            let q = self / rhs;
            let r = self % rhs;
            if (r == 0.into()) {
                q
            } else {
                q + u256 { low: 1_u128, high: 0_u128 }
            }
        }
    }

    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, value: u256) {}

    #[event]
    fn Approval(owner: ContractAddress, spender: ContractAddress, value: u256) {}

    impl ERC4626 of IERC4626 {
        ////////////////////////////////
        // ERC20 implementation
        ////////////////////////////////

        fn name() -> felt252 {
            _name::read()
        }

        fn symbol() -> felt252 {
            _symbol::read()
        }

        fn decimals() -> u8 {
            18_u8
        }

        fn total_supply() -> u256 {
            _total_supply::read()
        }

        fn balance_of(account: ContractAddress) -> u256 {
            _balances::read(account)
        }

        fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256 {
            _allowances::read((owner, spender))
        }

        fn transfer(recipient: ContractAddress, amount: u256) -> bool {
            let sender = get_caller_address();
            _transfer(sender, recipient, amount);
            true
        }

        fn transfer_from(
            sender: ContractAddress, recipient: ContractAddress, amount: u256
        ) -> bool {
            let caller = get_caller_address();
            _spend_allowance(sender, caller, amount);
            _transfer(sender, recipient, amount);
            true
        }

        fn approve(spender: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            _approve(caller, spender, amount);
            true
        }

        ////////////////////////////////
        // ERC4626-specific implementation
        ////////////////////////////////

        fn asset() -> ContractAddress {
            _asset::read().contract_address
        }

        fn total_assets() -> u256 {
            _asset::read().balance_of(get_contract_address())
        }

        fn convert_to_shares(assets: u256) -> u256 {
            if _total_supply::read() == 0.into() {
                assets
            } else {
                (assets * _total_supply::read()) / ERC4626::total_assets()
            }
        }

        fn convert_to_assets(shares: u256) -> u256 {
            let supply = _total_supply::read();
            if supply == 0.into() {
                shares
            } else {
                (shares * ERC4626::total_assets()) / supply
            }
        }

        fn max_deposit(amount: u256) -> u256 {
            BoundedInt::<u256>::max()
        }

        fn preview_deposit(assets: u256) -> u256 {
            ERC4626::convert_to_shares(assets)
        }

        fn deposit(assets: u256, receiver: ContractAddress) -> u256 {
            let shares = ERC4626::preview_deposit(assets);
            assert(shares != 0.into(), 'ZERO_SHARES');
            let caller = get_caller_address();
            let token = _asset::read();
            let self = get_contract_address();
            token.transfer_from(caller, get_contract_address(), assets);
            _mint(receiver, shares);
            //TODO emit deposit event
            shares
        }

        fn max_mint(receiver: ContractAddress) -> u256 {
            BoundedInt::<u256>::max()
        }

        fn preview_mint(shares: u256) -> u256 {
            if _total_supply::read() == 0.into() {
                shares
            } else {
                (shares * ERC4626::total_assets()).div_up(_total_supply::read())
            }
        }

        fn mint(shares: u256, receiver: ContractAddress) -> u256 {
            let assets = ERC4626::preview_mint(shares);
            let caller = get_caller_address();
            let token = _asset::read();
            let self = get_contract_address();
            token.transfer_from(caller, self, assets);
            _mint(receiver, shares);
            //TODO emit Deposit event
            shares
        }

        fn max_withdraw(owner: ContractAddress) -> u256 {
            ERC4626::convert_to_assets(_balances::read(owner))
        }

        fn preview_withdraw(assets: u256) -> u256 {
            if _total_supply::read() == 0.into() {
                assets
            } else {
                (assets * _total_supply::read()).div_up(ERC4626::total_assets())
            }
        }

        fn withdraw(assets: u256, receiver: ContractAddress, owner: ContractAddress) -> u256 {
            let shares = ERC4626::preview_withdraw(assets);

            if get_caller_address() != owner {
                let allowed = _allowances::read((owner, get_caller_address()));
                if allowed != BoundedInt::<u256>::max() {
                    let new_allowed = allowed - shares;
                    _allowances::write((owner, get_caller_address()), new_allowed);
                }
            }

            _burn(owner, shares);
            let token = _asset::read();
            token.transfer(receiver, assets);
            //TODO emit Withdraw event
            shares
        }

        fn max_redeem(owner: ContractAddress) -> u256 {
            ERC4626::balance_of(owner)
        }

        fn preview_redeem(shares: u256) -> u256 {
            ERC4626::convert_to_assets(shares)
        }

        fn redeem(shares: u256, receiver: ContractAddress, owner: ContractAddress) -> u256 {
            let assets = ERC4626::preview_redeem(shares);
            assert(assets != 0.into(), 'ZERO_ASSETS');

            if get_caller_address() != owner {
                let allowed = _allowances::read((owner, get_caller_address()));
                if allowed != BoundedInt::<u256>::max() {
                    let new_allowed = allowed - shares;
                    _allowances::write((owner, get_caller_address()), new_allowed);
                }
            }

            _burn(owner, shares);
            let token = _asset::read();
            token.transfer(receiver, assets);
            //TODO emit Withdraw event
            shares
        }
    }

    #[constructor]
    fn constructor(name: felt252, symbol: felt252, asset: ContractAddress) {
        initializer(name, symbol, asset);
    }

    ////////////////////////////////
    // ERC20 entrypoints
    ////////////////////////////////

    #[view]
    fn name() -> felt252 {
        ERC4626::name()
    }

    #[view]
    fn symbol() -> felt252 {
        ERC4626::symbol()
    }

    #[view]
    fn decimals() -> u8 {
        ERC4626::decimals()
    }

    #[view]
    fn total_supply() -> u256 {
        ERC4626::total_supply()
    }

    #[view]
    fn balance_of(account: ContractAddress) -> u256 {
        ERC4626::balance_of(account)
    }

    #[view]
    fn allowance(owner: ContractAddress, spender: ContractAddress) -> u256 {
        ERC4626::allowance(owner, spender)
    }

    #[external]
    fn transfer(recipient: ContractAddress, amount: u256) -> bool {
        ERC4626::transfer(recipient, amount)
    }

    #[external]
    fn transfer_from(sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool {
        ERC4626::transfer_from(sender, recipient, amount)
    }

    #[external]
    fn approve(spender: ContractAddress, amount: u256) -> bool {
        ERC4626::approve(spender, amount)
    }

    #[external]
    fn increase_allowance(spender: ContractAddress, added_value: u256) -> bool {
        _increase_allowance(spender, added_value)
    }

    #[external]
    fn decrease_allowance(spender: ContractAddress, subtracted_value: u256) -> bool {
        _decrease_allowance(spender, subtracted_value)
    }

    ////////////////////////////////////////////////////////////////
    // ERC4626 functions
    ////////////////////////////////////////////////////////////////

    #[view]
    fn asset() -> ContractAddress {
        ERC4626::asset()
    }

    #[view]
    fn total_assets() -> u256 {
        ERC4626::total_assets()
    }

    #[view]
    fn convert_to_shares(assets: u256) -> u256 {
        ERC4626::convert_to_shares(assets)
    }

    #[view]
    fn convert_to_assets(shares: u256) -> u256 {
        ERC4626::convert_to_assets(shares)
    }

    #[view]
    fn max_deposit(amount: u256) -> u256 {
        ERC4626::max_deposit(amount)
    }

    #[view]
    fn preview_deposit(assets: u256) -> u256 {
        ERC4626::preview_deposit(assets)
    }

    #[external]
    fn deposit(assets: u256, receiver: ContractAddress) -> u256 {
        ERC4626::deposit(assets, receiver)
    }

    #[view]
    fn max_mint(receiver: ContractAddress) -> u256 {
        ERC4626::max_mint(receiver)
    }

    #[view]
    fn preview_mint(shares: u256) -> u256 {
        ERC4626::preview_mint(shares)
    }

    #[external]
    fn mint(shares: u256, receiver: ContractAddress) -> u256 {
        ERC4626::mint(shares, receiver)
    }

    #[view]
    fn max_withdraw(owner: ContractAddress) -> u256 {
        ERC4626::max_withdraw(owner)
    }

    #[view]
    fn preview_withdraw(assets: u256) -> u256 {
        ERC4626::preview_withdraw(assets)
    }

    #[external]
    fn withdraw(assets: u256, receiver: ContractAddress, owner: ContractAddress) -> u256 {
        ERC4626::withdraw(assets, receiver, owner)
    }

    #[view]
    fn max_redeem(owner: ContractAddress) -> u256 {
        ERC4626::max_redeem(owner)
    }

    #[view]
    fn preview_redeem(shares: u256) -> u256 {
        ERC4626::preview_redeem(shares)
    }

    #[external]
    fn redeem(shares: u256, receiver: ContractAddress, owner: ContractAddress) -> u256 {
        ERC4626::redeem(shares, receiver, owner)
    }

    ///
    /// Internals
    ///

    fn initializer(name_: felt252, symbol_: felt252, asset: ContractAddress) {
        _name::write(name_);
        _symbol::write(symbol_);
        _asset::write(IERC20Dispatcher { contract_address: asset });
    }

    fn _increase_allowance(spender: ContractAddress, added_value: u256) -> bool {
        let caller = get_caller_address();
        _approve(caller, spender, _allowances::read((caller, spender)) + added_value);
        true
    }

    fn _decrease_allowance(spender: ContractAddress, subtracted_value: u256) -> bool {
        let caller = get_caller_address();
        _approve(caller, spender, _allowances::read((caller, spender)) - subtracted_value);
        true
    }

    fn _mint(recipient: ContractAddress, amount: u256) {
        assert(!recipient.is_zero(), 'ERC20: mint to 0');
        _total_supply::write(_total_supply::read() + amount);
        _balances::write(recipient, _balances::read(recipient) + amount);
        Transfer(Zeroable::zero(), recipient, amount);
    }

    fn _burn(account: ContractAddress, amount: u256) {
        assert(!account.is_zero(), 'ERC20: burn from 0');
        _total_supply::write(_total_supply::read() - amount);
        _balances::write(account, _balances::read(account) - amount);
        Transfer(account, Zeroable::zero(), amount);
    }

    fn _approve(owner: ContractAddress, spender: ContractAddress, amount: u256) {
        assert(!owner.is_zero(), 'ERC20: approve from 0');
        assert(!spender.is_zero(), 'ERC20: approve to 0');
        _allowances::write((owner, spender), amount);
        Approval(owner, spender, amount);
    }

    fn _transfer(sender: ContractAddress, recipient: ContractAddress, amount: u256) {
        assert(!sender.is_zero(), 'ERC20: transfer from 0');
        assert(!recipient.is_zero(), 'ERC20: transfer to 0');
        _balances::write(sender, _balances::read(sender) - amount);
        _balances::write(recipient, _balances::read(recipient) + amount);
        Transfer(sender, recipient, amount);
    }

    fn _spend_allowance(owner: ContractAddress, spender: ContractAddress, amount: u256) {
        let current_allowance = _allowances::read((owner, spender));
        let ONES_MASK = 0xffffffffffffffffffffffffffffffff_u128;
        let is_unlimited_allowance =
            current_allowance.low == ONES_MASK & current_allowance.high == ONES_MASK;
        if !is_unlimited_allowance {
            _approve(owner, spender, current_allowance - amount);
        }
    }
}
