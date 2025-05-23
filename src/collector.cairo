use starknet::ContractAddress;

#[starknet::interface]
pub trait ICollector<TContractState> {
    fn receive(ref self: TContractState, entropy: felt252, proof: Array<felt252>);

    fn set_reservoir(ref self: TContractState, new_reservoir: ContractAddress);
    fn set_contributors_hub(ref self: TContractState, new_contributors_hub: ContractAddress);
}

#[starknet::contract]
mod Collector {
    use starknet::storage::{StoragePointerWriteAccess, StoragePointerReadAccess};
    use core_v0::contributor::{IContributorHubDispatcher, IContributorHubDispatcherTrait};
    use core_v0::reservoir::{IEntropyReservoirDispatcher, IEntropyReservoirDispatcherTrait};
    use starknet::{ContractAddress, get_caller_address};
    use core::poseidon::poseidon_hash_span;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        contributors: IContributorHubDispatcher,
        reservoir: IEntropyReservoirDispatcher,
    }

    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress, contributors: IContributorHubDispatcher) {
        self.owner.write(owner);
        self.contributors.write(contributors);
    }

    #[abi(embed_v0)]
    impl CollectorImpl of super::ICollector<ContractState> {
        fn receive(ref self: ContractState, entropy: felt252, proof: Array<felt252>) {
            // check if caller is a contributor
            self.only_contributor();

            // check if entropy is valid
            let got = poseidon_hash_span(proof.span());

            assert(got == entropy, 'INVALID_ENTROPY');

            let value: u256 = entropy.into();

            // add randomness to the Reservoir
            self.get_reservoir().put(value);
        }

        fn set_reservoir(ref self: ContractState, new_reservoir: ContractAddress) {
            self.only_owner();
            self.reservoir.write(IEntropyReservoirDispatcher{contract_address: new_reservoir});
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

        fn get_reservoir(self: @ContractState) -> IEntropyReservoirDispatcher {
            self.reservoir.read()
        }
    }
}
