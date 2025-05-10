use starknet::ContractAddress;

#[starknet::interface]
pub trait IContributorHub<TContractState> {
    fn add(ref self: TContractState, contributor: ContractAddress);
    fn remove(ref self: TContractState, contributor: ContractAddress);

    fn exists(self: @TContractState, contributor: ContractAddress) -> bool;

    fn get_count(self: @TContractState) -> felt252;
}


#[starknet::contract]
mod ContributorHub {
    use starknet::storage::{
        Map,
        StorageMapReadAccess,
        StorageMapWriteAccess,
        StoragePointerReadAccess,
        StoragePointerWriteAccess,
    };
    use starknet::{ContractAddress, get_caller_address};

    #[storage]
    struct Storage {
        owner: ContractAddress,
        contributors: Map<ContractAddress, bool>,
        contributors_count: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
    }

    #[abi(embed_v0)]
    impl ContributorHubImpl of super::IContributorHub<ContractState> {
        fn add(ref self: ContractState, contributor: ContractAddress) {
            self.contributors.write(contributor, true);
            self.contributors_count.write(self.contributors_count.read() + 1);
        }

        fn remove(ref self: ContractState, contributor: ContractAddress) {
            self.only_owner();
            self.contributors.write(contributor, false);
            self.contributors_count.write(self.contributors_count.read() - 1);
        }

        fn exists(self: @ContractState, contributor: ContractAddress) -> bool {
            self.contributors.read(contributor)
        }

        fn get_count(self: @ContractState) -> felt252 {
            self.contributors_count.read()
        }
    }

    #[generate_trait]
    impl PrivateFunctions of PrivateFunctionsTrait {
        fn only_owner(self: @ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'ONLY_OWNER');
        }
    }
}
