object "Core" {
    code {
        // Constructor

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
            default {
                // if the function signature sent does not match any
                // of the contract functions, revert
                revert(0, 0)
            }
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

        /****************************************/
        /*             Storage read             */
        /****************************************/

        function owner() -> o {
            o := sload(ownerPos())
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

        function allocate(size) -> ptr {
            ptr := mload(0x40)
            if iszero(ptr) { ptr := 0x60 }
            mstore(0x40, add(ptr, size))
        }

    }
}