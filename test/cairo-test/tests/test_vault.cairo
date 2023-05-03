use starknet::syscalls::deploy_syscall;
use starknet::class_hash::Felt252TryIntoClassHash;
use starknet::contract_address::contract_address_const;
use starknet::ContractAddress;
use starknet::testing;
use starknet::get_contract_address;
use traits::Into;
use traits::TryInto;
use option::OptionTrait;
use result::ResultTrait;
use array::ArrayTrait;
use debug::PrintTrait;


use simple_vault::vault::Vault;
use simple_vault::vault::IVaultDispatcher;
use simple_vault::vault::IVaultDispatcherTrait;
use tests::mocks::mock_erc20::MockERC20;
use tests::mocks::mock_erc20::IMockERC20Dispatcher;
use tests::mocks::mock_erc20::IMockERC20DispatcherTrait;
use openzeppelin::token::erc20::IERC20Dispatcher;
use openzeppelin::token::erc20::IERC20DispatcherTrait;

fn setup() -> (IMockERC20Dispatcher, IVaultDispatcher) {
    // Set up.

    // Deploy mock token.

    let user1 = contract_address_const::<0x123456789>();

    let mut calldata = ArrayTrait::new();
    let name = 'Mock Token';
    let symbol = 'TKN';
    calldata.append(name);
    calldata.append(symbol);

    let (token_address, _) = deploy_syscall(
        MockERC20::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    ).unwrap();

    let mut calldata = ArrayTrait::<felt252>::new();
    calldata.append('Mock Token Vault');
    calldata.append('vwTKN');
    calldata.append(token_address.into());
    let (vault_address, _) = deploy_syscall(
        Vault::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    ).unwrap();

    let token = IMockERC20Dispatcher { contract_address: token_address };
    let vault = IVaultDispatcher { contract_address: vault_address };

    (token, vault)
}

#[test]
#[available_gas(2000000000000)]
fn test_atomic_deposit_withdratest_atomic_deposit_withdraww() {
    let (underlying, vault) = setup();
    let alice = contract_address_const::<0x123456789>();
// testing::set_contract_address(alice);
// underlying.mint(alice, 100.into());
// let vault_address = vault.contract_address;
// //TODO fix: calling underlying.approve() here causes a failed calculating gas usage here
// underlying.approve(vault.contract_address, 100.into());
// 'lol'.print();
// let pre_deposit_bal = underlying.balance_of(alice);
// vault.deposit(100.into(), alice);
//Convert from solidity
//         assertEq(vault.convertToAssets(10**vault.decimals()), 1e18);
//         assertEq(vault.totalStrategyHoldings(), 0);
//         assertEq(vault.totalAssets(), 1e18);
//         assertEq(vault.totalFloat(), 1e18);
//         assertEq(vault.balanceOf(address(this)), 1e18);
//         assertEq(vault.convertToAssets(vault.balanceOf(address(this))), 1e18);
//         assertEq(underlying.balanceOf(address(this)), preDepositBal - 1e18);

//         vault.withdraw(1e18, address(this), address(this));

//         assertEq(vault.convertToAssets(10**vault.decimals()), 1e18);
//         assertEq(vault.totalStrategyHoldings(), 0);
//         assertEq(vault.totalAssets(), 0);
//         assertEq(vault.totalFloat(), 0);
//         assertEq(vault.balanceOf(address(this)), 0);
//         assertEq(vault.convertToAssets(vault.balanceOf(address(this))), 0);
//         assertEq(underlying.balanceOf(address(this)), preDepositBal);

// assert(vault.convert_to_assets(100.into()) == 100.into(), 'convert_to_assets failed');
// // assert(vault.total_strategy_holdings() == 0.into()), 'total_strategy_holdings failed';
// assert(vault.total_assets() == 100.into(), 'total_assets failed');
// assert(vault.total_float() == 100.into(), 'total_float failed');
// assert(vault.balance_of(alice) == 100.into(), 'balance_of failed');
// assert(
//     vault.convert_to_assets(vault.balance_of(alice)) == 100.into(), 'convert_to_assets failed'
// );
// assert(
//     underlying.balance_of(alice) == pre_deposit_bal - 100.into(), 'underlying.balance_of failed'
// );
// vault.withdraw(100.into(), alice, alice);

// assert(vault.convert_to_assets(100.into()) == 100.into(), 'convert_to_assets failed');
// // assert(vault.total_strategy_holdings() == 0.into()), 'total_strategy_holdings failed';
// assert(vault.total_assets() == 0.into(), 'total_assets failed');
// assert(vault.total_float() == 0.into(), 'total_float failed');
// assert(vault.balance_of(alice) == 0.into(), 'balance_of failed');
// assert(
//     vault.convert_to_assets(vault.balance_of(alice)) == 0.into(), 'convert_to_assets failed'
// );
// assert(underlying.balance_of(alice) == pre_deposit_bal, 'underlying.balance_of failed');
}

