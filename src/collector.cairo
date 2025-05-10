use starknet::ContractAddress;

#[derive(Copy, Drop, Serde)]
pub struct Randomness {
    pub value: felt252,
    pub proof: felt252,
}

#[starknet::interface]
pub trait ICollector<TContractState> {
    fn receive(ref self: TContractState, randomness: Randomness);

    fn set_reservoir(ref self: TContractState, new_reservoir: ContractAddress);
    fn set_contributors_hub(ref self: TContractState, new_contributors_hub: ContractAddress);
}

#[starknet::contract]
mod Collector {
    use starknet::storage::{StoragePointerWriteAccess, StoragePointerReadAccess};
    use core_v0::contributor::{IContributorHubDispatcher, IContributorHubDispatcherTrait};
    use core_v0::reservoir::{IReservoirDispatcher, IReservoirDispatcherTrait, IReservoirSafeDispatcher};
    use starknet::{ContractAddress, get_caller_address};

    use super::{Randomness};

    #[storage]
    struct Storage {
        owner: ContractAddress,
        contributors: IContributorHubDispatcher,
        reservoir: IReservoirDispatcher,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, contributors: IContributorHubDispatcher) {
        self.owner.write(owner);
        self.contributors.write(contributors);
    }

    #[abi(embed_v0)]
    impl CollectorImpl of super::ICollector<ContractState> {
        fn receive(ref self: ContractState, randomness: Randomness) {
            // check if caller is a contributor
            self.only_contributor();

            // check if randomness is valid
            assert(self.verify_randomness(randomness), 'INVALID_RANDOMNESS');

            // add randomness to the Reservoir
            self.get_reservoir().put(randomness.value);
        }

        fn set_reservoir(ref self: ContractState, new_reservoir: ContractAddress) {
            self.only_owner();
            self.reservoir.write(IReservoirDispatcher{contract_address: new_reservoir});
        }

        fn set_contributors_hub(ref self: ContractState, new_contributors_hub: ContractAddress) {
            self.only_owner();
            self.contributors.write(IContributorHubDispatcher{contract_address: new_contributors_hub});
        }
    }

    #[generate_trait]
    impl PrivateFunctions of PrivateFunctionsTrait {
        fn only_owner(self: @ContractState) {
            let caller = get_caller_address();
            assert(caller == self.owner.read(), 'ONLY_OWNER');
        }

        fn only_contributor(self: @ContractState) {
            let caller = get_caller_address();
            assert(
                self.get_contributors_hub().exists(caller),
                'ONLY_CONTRIBUTOR'
            )
        }

        fn get_contributors_hub(self: @ContractState) -> IContributorHubDispatcher {
            self.contributors.read()
        }

        fn get_reservoir(self: @ContractState) -> IReservoirDispatcher {
            self.reservoir.read()
        }

        fn verify_randomness(self: @ContractState, randomness: Randomness) -> bool {
            // TODO: implement verification
            true
        }
    }
}
