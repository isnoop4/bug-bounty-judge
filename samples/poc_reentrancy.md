1. Deploy Vault, deposit 1 ETH from account A.
2. Attacker deploys a contract whose receive() calls withdraw(1 ether) again.
3. Attacker deposits 1 ETH, then calls withdraw(1 ether).
4. receive() is triggered before the balance is reduced, so withdraw repeats until the Vault is empty.
Result: all ETH belonging to all users is drained.
