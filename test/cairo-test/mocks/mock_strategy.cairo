use starknet::ContractAddress;
use openzeppelin::token::erc20::IERC20;

#[abi]
trait IMockStrategy {
    fn invest(amount: u256);
    fn withdraw(sender: ContractAddress, amount: u256) -> u256;
    fn balance_of_underlying(vault: ContractAddress) -> u256;
    fn simulate_value_change(value_change: u256, positive: bool);
}

#[contract]
mod MockStrategy {
    use tests::mocks::mock_erc20::{IMockERC20, IMockERC20Dispatcher, IMockERC20DispatcherTrait};
    use starknet::ContractAddress;
    use starknet::{get_caller_address, get_contract_address};
    use option::OptionTrait;
    use traits::Into;

    struct Storage {
        _dai_token: IMockERC20Dispatcher,
        _invested_balance: LegacyMap<ContractAddress, u256>,
        _exchange_rate: u256
    }

    #[constructor]
    fn constructor(dai_address: ContractAddress) {
        _dai_token::write(IMockERC20Dispatcher { contract_address: dai_address })
    }

    #[external]
    fn invest(amount: u256) {
        let caller = get_caller_address();
        _dai_token::read().transfer_from(caller, get_caller_address(), amount);
        _invested_balance::write(caller, _invested_balance::read(caller) + amount)
    }

    #[external]
    fn withdraw(amount: u256) {
        let caller = get_caller_address();
        assert(_invested_balance::read(caller) >= amount, 'NOT_ENOUGH_BALANCE');
        _dai_token::read().transfer(caller, amount);
        _invested_balance::write(caller, _invested_balance::read(caller) - amount)
    }

    #[view]
    fn balance_of_underlying(account: ContractAddress) -> u256 {
        let WAD: u256 = 1000000000000000000.into();
        mul_div_down(_invested_balance::read(account), _exchange_rate::read(), WAD)
    }

    #[external]
    fn simulate_value_change(value_change: u256, positive: bool) {
        let current_holdings = _dai_token::read().balance_of(get_contract_address());
        if positive {
            _dai_token::read().mint(get_contract_address(), value_change);
            let new_exch_rate = div_wad_down(
                (current_holdings + value_change), current_holdings
            ); // VALUE IN WAD
        } else {
            assert(
                _dai_token::read().balance_of(get_contract_address()) >= value_change,
                'Cant simulate decrease'
            );
            _dai_token::read().burn(get_contract_address(), value_change);
            let new_exch_rate = div_wad_down(
                (current_holdings - value_change), current_holdings
            ); // VALUE IN WAD
        }
    }

    //TODO move this outside in utils

    fn div_wad_down(a: u256, b: u256) -> u256 {
        let WAD: u256 = 1000000000000000000.into();
        mul_div_down(a, WAD, b)
    }

    fn mul_div_down(a: u256, b: u256, denominator: u256) -> u256 {
        (a * b) / denominator
    }
}


#[cfg(test)]
mod test {//TODO(low priority)
}
