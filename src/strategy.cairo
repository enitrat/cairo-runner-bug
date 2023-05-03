#[abi]
trait IStrategy {
    fn deposit(amount: u256);
    fn withdraw(amount: u256);
}
