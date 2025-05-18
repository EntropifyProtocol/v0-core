use starknet::ContractAddress;

#[starknet::interface]
pub trait IFeeCollector<TContractState> {
    fn collect(ref self: TContractState, sender: ContractAddress, amount: u256);
    fn withdraw(ref self: TContractState);
}

#[starknet::contract]
mod FeeCollector {
    use starknet::storage::{StoragePointerWriteAccess, StoragePointerReadAccess};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    use openzeppelin_token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};

    #[storage]
    struct Storage {
        token: IERC20Dispatcher,
        owner: ContractAddress,
        rate: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState, token: IERC20Dispatcher, owner: ContractAddress) {
        self.token.write(token);
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl FeeCollectorImpl of super::IFeeCollector<ContractState> {
        fn collect(ref self: ContractState, sender: ContractAddress, amount: u256) {
            let fee = self.rate.read();

            if fee > 0 {
                assert(fee >= amount, 'INSUFFICIENT_FUNDS');
                self.get_token().transfer_from(sender, get_contract_address(), fee);
            }
        }

        fn withdraw(ref self: ContractState) {
            self.only_owner();

            let owner = self.owner.read();
            let contract_address = get_contract_address();
            
            let balance = self.get_token().balance_of(contract_address);

            self.get_token().transfer(owner, balance);
        }
    }

    #[generate_trait]
    impl PrivateFunctions of PrivateFunctionsTrait {
        fn only_owner(self: @ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'ONLY_OWNER');
        }

        fn set_fee(ref self: ContractState, rate: u256) {
            self.rate.write(rate);
        }

        fn get_token(self: @ContractState) -> IERC20Dispatcher {
            self.token.read()
        }
    }
}