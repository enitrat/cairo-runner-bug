use openzeppelin::token::erc20::IERC20Dispatcher;
use openzeppelin::token::erc20::IERC20DispatcherTrait;
use simple_vault::yield_token::YieldToken;

use starknet::class_hash::Felt252TryIntoClassHash;
use starknet::ContractAddress;
use starknet::contract_address::contract_address_const;
use array::ArrayTrait;
use traits::Into;
use traits::TryInto;
use result::ResultTrait;
use option::OptionTrait;
use starknet::testing;
use starknet::syscalls::deploy_syscall;
use debug::PrintTrait;

fn setup() -> IERC20Dispatcher {
    // Set up.

    // Deploy mock token.

    let alice = contract_address_const::<0xABCD>();

    let mut calldata = ArrayTrait::new();
    let name = 'Yield Token';
    let symbol = 'YTKN';
    let initial_supply_low = 100;
    let initial_supply_high = 0;
    let recipient: felt252 = alice.into();
    calldata.append(name);
    calldata.append(symbol);
    calldata.append(initial_supply_low);
    calldata.append(initial_supply_high);
    calldata.append(recipient);

    let (token_address, _) = deploy_syscall(
        YieldToken::TEST_CLASS_HASH.try_into().unwrap(), 0, calldata.span(), false
    ).unwrap();

    let token = IERC20Dispatcher { contract_address: token_address };

    token
}

#[test]
#[available_gas(2000000)]
fn test_balance_accrual() {
    let token = setup();
    let alice = contract_address_const::<0xABCD>();
    let balance_before = token.balance_of(alice);
    assert(balance_before == 100.into(), 'wrong initial balance');

    testing::set_block_timestamp(60 * 60 * 24 + 1);
    let balance_after = token.balance_of(alice);
    assert(balance_after == 101.into(), 'wrong balance after 1 day');
}

