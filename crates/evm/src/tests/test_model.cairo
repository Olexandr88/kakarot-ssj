mod test_contract_account;
mod test_eoa;
use contracts::kakarot_core::interface::IExtendedKakarotCoreDispatcherTrait;
use contracts::tests::test_utils::{
    setup_contracts_for_testing, fund_account_with_native_token, deploy_contract_account
};
use contracts::contract_account::{IContractAccountDispatcherTrait, IContractAccountDispatcher};
use evm::model::account::AccountTrait;
use evm::model::{Account, ContractAccountTrait, AccountType, EOATrait, AddressTrait};
use evm::tests::test_utils::{evm_address};
use openzeppelin::token::erc20::interface::IERC20CamelDispatcherTrait;
use starknet::testing::set_contract_address;

#[test]
#[available_gas(20000000)]
fn test_is_deployed_eoa_exists() {
    // Given
    let (native_token, kakarot_core) = setup_contracts_for_testing();
    let eoa_address = EOATrait::deploy(evm_address()).expect('failed deploy eoa account',);

    // When

    // When
    set_contract_address(kakarot_core.contract_address);
    let is_deployed = evm_address().is_deployed();

    // Then
    assert(is_deployed, 'account should be deployed');
}

#[test]
#[available_gas(20000000)]
fn test_is_deployed_ca_exists() {
    // Given
    let (native_token, kakarot_core) = setup_contracts_for_testing();
    deploy_contract_account(evm_address(), array![].span());

    // When
    let is_deployed = evm_address().is_deployed();
    // Then
    assert(is_deployed, 'account should be deployed');
}

#[test]
#[available_gas(20000000)]
fn test_is_deployed_undeployed() {
    // Given
    let (native_token, kakarot_core) = setup_contracts_for_testing();

    // When
    set_contract_address(kakarot_core.contract_address);
    let is_deployed = evm_address().is_deployed();

    // Then
    assert(!is_deployed, 'account shouldnt be deployed');
}


#[test]
#[available_gas(5000000)]
fn test_account_balance_eoa() {
    // Given
    let (native_token, kakarot_core) = setup_contracts_for_testing();
    let eoa_address = EOATrait::deploy(evm_address()).expect('failed deploy eoa account',);

    fund_account_with_native_token(eoa_address.starknet, native_token, 0x1);

    // When
    set_contract_address(kakarot_core.contract_address);
    let account = AccountTrait::fetch(evm_address()).unwrap().unwrap();
    let balance = account.balance().unwrap();

    // Then
    assert(balance == native_token.balanceOf(eoa_address.starknet), 'wrong balance');
}

#[test]
#[available_gas(5000000)]
fn test_address_balance_eoa() {
    // Given
    let (native_token, kakarot_core) = setup_contracts_for_testing();
    let eoa_address = EOATrait::deploy(evm_address()).expect('failed deploy eoa account',);

    fund_account_with_native_token(eoa_address.starknet, native_token, 0x1);

    // When
    set_contract_address(kakarot_core.contract_address);
    let account = AccountTrait::fetch(evm_address()).unwrap().unwrap();
    let balance = account.balance().unwrap();

    // Then
    assert(balance == native_token.balanceOf(eoa_address.starknet), 'wrong balance');
}


#[test]
#[available_gas(5000000)]
fn test_account_exists_eoa() {
    // Given
    let (native_token, kakarot_core) = setup_contracts_for_testing();
    let mut eoa_address = EOATrait::deploy(evm_address()).expect('failed deploy eoa',);

    // When
    let account = AccountTrait::fetch(evm_address()).unwrap().unwrap();

    // Then
    assert(account.exists() == true, 'account should be deployed');
}


#[test]
#[available_gas(5000000)]
fn test_account_exists_contract_account() {
    // Given
    let (native_token, kakarot_core) = setup_contracts_for_testing();
    let mut ca_address = deploy_contract_account(evm_address(), array![].span());

    // When
    let account = AccountTrait::fetch(evm_address()).unwrap().unwrap();

    // Then
    assert(account.exists() == true, 'account should be deployed');
}


#[test]
#[available_gas(5000000)]
fn test_account_exists_undeployed() {
    // Given
    let (native_token, kakarot_core) = setup_contracts_for_testing();

    // When
    let account = AccountTrait::fetch_or_create(evm_address()).unwrap();

    // Then
    assert(account.exists() == false, 'account should be deployed');
}

#[test]
#[available_gas(5000000)]
fn test_account_exists_account_to_deploy() {
    // Given
    let (native_token, kakarot_core) = setup_contracts_for_testing();

    // When
    let mut account = AccountTrait::fetch_or_create(evm_address()).unwrap();
    // Mock account as an existing contract account in the cached state.
    account.account_type = AccountType::ContractAccount;
    account.nonce = 1;
    account.code = array![0x1].span();

    // Then
    assert(account.exists() == true, 'account should exist');
}


#[test]
#[available_gas(5000000)]
fn test_account_balance_contract_account() {
    // Given
    let (native_token, kakarot_core) = setup_contracts_for_testing();
    let mut ca_address = deploy_contract_account(evm_address(), array![].span());

    fund_account_with_native_token(ca_address.starknet, native_token, 0x1);

    // When
    let account = AccountTrait::fetch(evm_address()).unwrap().unwrap();
    let balance = account.balance().unwrap();

    // Then
    assert(balance == native_token.balanceOf(ca_address.starknet), 'wrong balance');
}

#[test]
#[available_gas(5000000)]
fn test_account_commit_already_deployed() {
    let (native_token, kakarot_core) = setup_contracts_for_testing();
    let mut ca_address = deploy_contract_account(evm_address(), array![].span());

    // When
    let mut account = AccountTrait::fetch(evm_address()).unwrap().unwrap();
    account.nonce = 420;
    account.code = array![0x1].span();
    account.commit().unwrap();

    // Then
    let account_dispatcher = IContractAccountDispatcher { contract_address: ca_address.starknet };
    let nonce = account_dispatcher.nonce();
    let code = account_dispatcher.bytecode();
    assert(nonce == 420, 'wrong nonce');
    assert(code == array![0x1].span(), 'wrong code');
}

#[test]
#[available_gas(5000000)]
fn test_account_commit_already_deployed_should_deploy() {
    let (native_token, kakarot_core) = setup_contracts_for_testing();
    let mut ca_address = deploy_contract_account(evm_address(), array![].span());

    // When
    let mut account = AccountTrait::fetch(evm_address()).unwrap().unwrap();
    account.nonce = 420;
    account.code = array![0x1].span();
    account.commit().unwrap();

    // Then
    let account_dispatcher = IContractAccountDispatcher { contract_address: ca_address.starknet };
    let nonce = account_dispatcher.nonce();
    let code = account_dispatcher.bytecode();
    assert(nonce == 420, 'wrong nonce');
    assert(code == array![0x1].span(), 'wrong code');
}

#[test]
#[available_gas(5000000)]
fn test_address_balance_contract_account() {
    // Given
    let (native_token, kakarot_core) = setup_contracts_for_testing();
    let mut ca_address = deploy_contract_account(evm_address(), array![].span());

    fund_account_with_native_token(ca_address.starknet, native_token, 0x1);

    // When
    let account = AccountTrait::fetch(evm_address()).unwrap().unwrap();
    let balance = account.balance().unwrap();

    // Then
    // Then
    assert(balance == native_token.balanceOf(ca_address.starknet), 'wrong balance');
}
