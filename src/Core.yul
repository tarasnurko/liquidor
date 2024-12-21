/*
-- STORAGE LAYOUT --
slot 0          - owner address
slot 1          - connector address

slot 0x1000     - mapping(address token => Data)
     0x00       - totalDeposits
     0x20       - totalShares                                                      

slot 0x10000    - mapping(address account => mapping(address token => uint256 shares)) userShares

*/

object "Core" {
    code {
        // return the bytecode of the contract
        datacopy(0x00, dataoffset("runtime"), datasize("runtime"))
        return(0x00, datasize("runtime"))
    }

    // The code of the contract
    object "runtime" {
        code {
            // Revert if ether sent
            if iszero(iszero(callvalue())) {    
                revert(0, 0)
            }

            let selector := shr(0xe0, calldataload(0))

            // to get function signature use "cast sig"
            switch selector
            case 0x8da5cb5b {
                mstore(0x00, owner())
                return(0x00, 0x20)
            }
            case 0x13af4035 { // setOwner(address)
                require(iszero(owner())) // owner must not be empty
                setOwner(decodeAsAddress(0))
            }
            case 0x83f3084f { // connector()
                mstore(0x00, connector())
                return(0x00, 0x20)
            }
            case 0x10188aef { // setConnector(address) | setConnector(address newConnectorAddr)
                require(eq(caller(), owner())) // check that msg.sender is caller

                let c := decodeAsAddress(0)
                setConnector(c)
            }
            case 0x47e7ef24 { // deposit(address,uint256) | deposit(address token, uint256 amount)
                deposit(decodeAsAddress(0), decodeAsUint(1))
            }
            default {
                // if the function signature sent does not match any
                // of the contract functions, revert
                revert(0, 0)
            }

            /****************************************/
            /*           External functions         */
            /****************************************/

            // lender supply token in protocol
            // by default 90% of those tokens go immediately to yield farming protocol (AAVE)
            // other 10% are stored in contract to allow immediate borrowing/withdrawals 
            // user receive shares
            function deposit(token, amount) {
                // deposit tokens to AAVE???

                /*
                    when user name deposits how to calculate user earned yield?
                    if we save only user deposits and calculate rewards based on deposits user can just deposit 100 tokens and immediately withdraw
                    in that case we probably can use ERC4626 contracts for shares and that would mitigate such problem
                    but if I want to deploy Vault for each asset it would cost a lot of gas
                        - if I want to use beacon proxy it would take too much time
                        - additional management of derived contracts would take too much time also

                    so dor that I need to manage shares internally
                    so when user make deposit we only manage assetsToShares
                    to make ERC4626 calculations I need to save also totalAssets and totalShares
                    and when user make withdraw he exchanges shares for tokens which are withdrawn from aave
                    and at that time protocol charges 5% of profit:

                    seems good
                */

                let sharesAmount := convertToShares(token, amount)

                // withdraw from user and deposit to aave
                depositToAave(caller(), token, amount)

                addTokenDeposits(token, amount)
                addTokenShares(token, sharesAmount)

                addAccountTokenShares(caller(), token, sharesAmount)
            }   

            function withdraw(token, shares) {
                // check generated yield:
                // 1. check user have deposit shares
                // 2. retrieve aToken from AAVE for `token`
                // 3. get diff of aTokenBalance - tokenTotalDeposits()
                // 3.1 actuall diff is 95% of diff as 5% of earned yield ges to protocol
                // 3.2 this 5% fee must be saved
                // 4. now new totalDeposits = tokenTotalDeposits() + diff
                // 5. convertToShares `shares` and send user 
                // 6. reduce speified amount from user balance

                let userSharesBalance := accountTokenShares(caller(), token)

                // check that user have enough smount of shares on balance, i.e. if shares > balance
                // - if userSharesBalance < shares -> 1 -> iszero(1) -> false -> revert
                // - if userSharesBalance >= shares -> 0 -> iszero(0) -> true -> not revert
                require(iszero(lt(userSharesBalance, shares)))
                
                // TODO: add logic to calculate shares -> assets
                // add logic to calculate profit (earned yield per user shares)

                // TODO: reduce total token deposits and shares

                reduceAccountTokenShares(caller(), token, shares)
            }

            function borrow(borrowToken, borrowTokenAmount, collateralToken, collateralTokenAmount) {
                /*
                    [] how to manage borrow position generated yield???

                    save borrow position next with data: borrowToken, borrowTokenAmount, collateralToken, collateralTokenAmount
                    deposit all collateralTokenAmount to aave and
                        - increate total token amount
                        - increase total token shares
                        - save position shares
                    
                    allow user to deposit tokens only if it's 120% of LTV (in USDT)
                    to retrieve price probably use Uniswap v3 Price oracle

                    send necessary amount of borrowToken to user

                    [] how to check is user is subsequent to liquidation
                    1. get user position
                    2. get user amount of collateral token shares
                    2.1 substract fee from this collateral token shares
                    3. get amount of collateral token for amount of shares
                    
                    then for health use default formula for health factor
                    
                    in that case use LTV 101%

                    and with that user have additional health factor from generated yield

                    [] how to liquidate

                    [] how to repay position
                    if user want to repay position then he need to send amount of borrowed tokens back 
                    user would recieve back initial collateral token 
                    and protocol would get all generated yield
                    in that case most of yield goes to users 
                    and fee (5%) goes to safe guard

                */

                // 1. check that for existing tokens there is available amount
                // 2. check health factor 

                // health factor or borrow = 
                // collateral (USDT value) * LTV (for borrow it's 120%)
                // ---------------------------------------------------- > 1
                //             borrow tokens (in USDT)

                // 3. withdraw token necessary amount from AAVE
                // 4. send those withdrawed tokens to user
                // 5. save borrow position to storage 
            }

            /****************************************/
            /*             Storage layout           */
            /****************************************/

            function ownerPos() -> p { p := 0 }
            function connectorPos() -> p { p := 1 }

            /* --- Tokens --- */

            // total token depoists offset
            function tokenToStorageOffset(token) -> offset {
                offset := getMappingOffset(0x1000, token)
            }

            // total token shares offset
            function tokenSharesStorageOffset(token) -> offset {
                offset := tokenToStorageOffset(token)
                offset := add(0x20, offset)
            }

            /* --- Account shares --- */

            function accountTokenToSharesStorageOffset(account, token) -> offset {
                offset := getMappingOffset(0x10000, token) // inner mapping key
                offset := getNestedMappingOffset(offset, account)
            }

            /****************************************/
            /*             Storage read             */
            /****************************************/

            /* --- Global --- */

            function owner() -> v {
                v := sload(ownerPos())
            }

            function connector() -> v {
                v := sload(connectorPos())
            }

            // total token deposits
            function tokenDeposits(token) -> v {
                let offset := tokenToStorageOffset(token)
                v := sload(offset)
            }

            function tokenShares(token) -> v {
                let offset := tokenSharesStorageOffset(token)
                v := sload(offset)
            }

            /* --- Account shares --- */  

            function accountTokenShares(account, token) -> v {
                let offset := accountTokenToSharesStorageOffset(account, token)
                v := sload(offset)
            }

            /****************************************/
            /*        Storage modifications         */
            /****************************************/

            function setOwner(addr) {
                sstore(ownerPos(), addr)
            }

            function setConnector(addr) {
                sstore(connectorPos(), addr)
            }

            /**
             * @param token - deposited token address
             * @param amount - deposited token amount to add
             */  
            function addTokenDeposits(token, amount) {
                let offset := tokenToStorageOffset(token)
                let prevValue := tokenDeposits(token)
                sstore(offset, add(prevValue, amount))
            }

            /**
             * @param token - deposited token address
             * @param amount - deposited token shares to add
             */        
            function addTokenShares(token, amount) {
                let offset := tokenSharesStorageOffset(token)
                let prevValue := tokenShares(token)
                sstore(offset, add(prevValue, amount))
            }

            /* --- Account shares --- */  

            /**
             * @param amount - amount of shares to add to account in specified token
            */
            function addAccountTokenShares(account, token, amount) {
                let offset := accountTokenToSharesStorageOffset(account, token)
                let prevValue := accountTokenShares(account, token)
                sstore(offset, add(prevValue, amount))
            }

            /**
             * @param amount - amount of shares to reduce from account in specified token
            */
            function reduceAccountTokenShares(account, token, amount) {
                let offset := accountTokenToSharesStorageOffset(account, token)
                let prevValue := accountTokenShares(account, token)
                sstore(offset, sub(prevValue, amount))
            }

            /****************************************/
            /*     Shares logic (ERC4626 like)      */
            /****************************************/

            /**
             * @param token address of token
             * @param assets amount of assets to convert to shares
             */
            function convertToShares(token, assets) -> v {
                let totalAssets := tokenDeposits(token)
                let totalShares := tokenShares(token)

                // (assets * (totalShares + 1)) / totalAssets
                v := mulDivUp(assets, add(totalShares, 1), totalAssets)
            }

            function convertToAssets(token, shares) -> v {
                let totalAssets := tokenDeposits(token)
                let totalShares := tokenShares(token)

                // (shares * (totalAssets + 1)) / totalShares
                v := mulDivDown(shares, add(totalAssets, 1), totalShares)
            }

            /****************************************/
            /*               Connector              */
            /****************************************/

            function depositToAave(depositor, token, amount) {
                let ptr := mload(0x40)
                
                // deposit(address,address,uint256) -> 0x8340f549
                mstore(ptr, 0x8340f54900000000000000000000000000000000000000000000000000000000)
                
                mstore(add(ptr, 0x04), and(depositor, 0xffffffffffffffffffffffffffffffffffffffff))  // depositor address
                mstore(add(ptr, 0x24), and(token, 0xffffffffffffffffffffffffffffffffffffffff))      // token address
                mstore(add(ptr, 0x44), amount)                                                       // amount
                
                // Update free memory pointer
                mstore(0x40, add(ptr, 0x64))
                
                // Make the call
                let success := call(
                    gas(),            // gas
                    connector(),  // target contract
                    0,               // no ETH value
                    ptr,             // input pointer
                    0x64,            // input size (4 + 32 * 3 = 100 bytes)
                    ptr,             // output pointer
                    0                // output size (no return value expected)
                )
                
                // Check if call was successful
                if iszero(success) {
                    // Forward any revert message
                    returndatacopy(ptr, 0, returndatasize())
                    revert(ptr, returndatasize())
                }
            }

            /****************************************/
            /*     Calldata decoding functions      */
            /****************************************/

            // https://docs.soliditylang.org/en/latest/yul.html#complete-erc20-example
            function decodeAsAddress(offset) -> v {
                v := decodeAsUint(offset)
                if iszero(iszero(and(v, not(0xffffffffffffffffffffffffffffffffffffffff)))) {
                    revert(0, 0)
                }
            }

            // https://docs.soliditylang.org/en/latest/yul.html#complete-erc20-example
            function decodeAsUint(offset) -> v {
                let pos := add(4, mul(offset, 0x20))
                if lt(calldatasize(), add(pos, 0x20)) { // revert if there is less data then parameter position
                    revert(0, 0)
                }
                v := calldataload(pos)
            }

            /****************************************/
            /*              Utilities               */
            /****************************************/

            function calledByOwner() -> cbo {
                cbo := eq(owner(), caller())
            }

            // Check value is not zero (i.e. not false)
            function require(condition) {
                if iszero(condition) { revert(0, 0) }
            }

            // revert if `addr` is not contract
            function requireIsContract(addr) {
                if iszero(extcodesize(addr)) {
                    revert(0,0)
                }
            }

            function allocate(size) -> ptr {
                ptr := mload(0x40)
                if iszero(ptr) { ptr := 0x60 }
                mstore(0x40, add(ptr, size))
            }

            // for regular or inner mappings
            function getMappingOffset(slot, key) -> offset {
                mstore(0x00, key) 
                mstore(0x20, slot)  
                offset := keccak256(0x00, 0x40)
            }

            // for nested mapings
            function getNestedMappingOffset(mappingOffset, key) -> offset {
                mstore(0x00, key) 
                mstore(0x20, mappingOffset)  
                offset := keccak256(0x00, 0x40)
            }

            /****************************************/
            /*                Math                  */
            /****************************************/

            // x * y / denominator
            // Rounded up
            // https://github.com/transmissions11/solmate/blob/c93f7716c9909175d45f6ef80a34a650e2d24e56/src/utils/FixedPointMathLib.sol#L53-L69
            function mulDivUp(x, y, denominator) -> v {
                if iszero(mul(denominator, iszero(mul(y, gt(x, div(not(0), y)))))) {
                    revert(0, 0)
                }
                v := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
            }

            // x * y / denominator
            // Rounded down
            // https://github.com/transmissions11/solmate/blob/c93f7716c9909175d45f6ef80a34a650e2d24e56/src/utils/FixedPointMathLib.sol#L36-L51
            function mulDivDown(x, y, denominator) -> v {
                if iszero(mul(denominator, iszero(mul(y, gt(x, div(not(0), y)))))) {
                    revert(0, 0)
                }
                v := div(mul(x, y), denominator)
            }
        }
    }
}