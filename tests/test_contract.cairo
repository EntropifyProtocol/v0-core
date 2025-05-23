use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait, DeclareResultTrait, test_address};

use core_v0::reservoir::{IEntropyReservoirDispatcher, IEntropyReservoirDispatcherTrait};
use core_v0::reservoir::{IEntropyReservoirSafeDispatcher, IEntropyReservoirSafeDispatcherTrait};
use core::poseidon::poseidon_hash_span;

fn deploy_contract(name: ByteArray, owner: ContractAddress) -> ContractAddress {
    let contract = declare(name).unwrap().contract_class();
    let mut constructor_args = ArrayTrait::new();
    constructor_args.append(owner.into());
    
    let (contract_address, _) = contract.deploy(@constructor_args).unwrap();
    contract_address
}

#[test]
fn test_increase_balance() {
    let contract_address = deploy_contract("EntropyReservoir", test_address());

    let dispatcher = IEntropyReservoirDispatcher { contract_address };

    let count_before = dispatcher.get_count();
    assert(count_before == 0, 'Invalid balance');

    let values = [3, 1, 3, 5, 2, 2, 1, 2, 3, 1, 2, 1, 1, 1, 0, 3, 2, 5, 1, 3, 1, 2, 2, 1, 2, 1, 2, 3, 2, 2, 1, 2];
    let gott = poseidon_hash_span(values.span());
    println!("POSEIDON {}", gott);

    dispatcher.put(42);

    let count_after = dispatcher.get_count();
    assert(count_after == 1, 'Invalid balance');

    let entropy = dispatcher.get();
    assert(entropy == 42, 'Invalid entropy');


}

#[test]
#[feature("safe_dispatcher")]
fn test_cannot_increase_balance_with_zero_value() {
    let contract_address = deploy_contract("EntropyReservoir", test_address());

    let safe_dispatcher = IEntropyReservoirSafeDispatcher { contract_address };

    let count_before = safe_dispatcher.get_count().unwrap();
    assert(count_before == 0, 'Invalid count');

   safe_dispatcher.put(42).unwrap();

   let count_after = safe_dispatcher.get_count().unwrap();
   assert(count_after == 1, 'Invalid count');

   let entropy = safe_dispatcher.get().unwrap();
   assert(entropy == 42, 'Invalid entropy');
}
