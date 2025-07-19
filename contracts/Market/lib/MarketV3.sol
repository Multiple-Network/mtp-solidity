// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IWBNB} from "contracts/Market/interface/IWBNB.sol";
import "contracts/Market/interface/IUniV3.sol";

contract UniswapV3Swap {
    // IERC20 public ASTAR;
    // IERC20 public V_ATAR;
    address public cardOwner;
    ISwapRouter public router;
    IUniV3Factory public factory;
    address public constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    // INonfungiblePositionManager public nonfungiblePositionManager;
    // address immutable astar;
    // address immutable vastr;

    address immutable token0;
    address immutable token1;

    // address astar_,
    // address vastr_,
    // address nonfungiblePositionManager_

    constructor(address router_, address factory_) {
        // astar = astar_;
        // vastr = vastr_;
        // ASTAR = IERC20(astar_);
        // V_ATAR = IERC20(vastr_);
        // (token0, token1) = astar < vastr_ ? (astar, vastr_) : (vastr_, astar);
        router = ISwapRouter(router_);
        factory = IUniV3Factory(factory_);
        // nonfungiblePositionManager = INonfungiblePositionManager(
        //     nonfungiblePositionManager_
        // );
    }

    /**
     * @dev to withdraw WBNB to BNB
     * @param amount WBNB amount
     **/
    function withdrawWBNB(uint amount) internal {
        IWBNB(WBNB).withdraw(amount);
    }

    /**
     * @dev to get the nearest tick to add liquidity
     * @param currentTick Current tick of the pool
     * @param space Space between ticks
     **/
    function getNearestTick(
        int24 currentTick,
        int24 space
    ) internal pure returns (int24) {
        if (currentTick == 0) {
            return 0;
        }
        // Determines direction
        int24 direction = int24(currentTick >= 0 ? int8(1) : -1);
        // Changes direction
        currentTick *= direction;
        // Calculates nearest tick based on how close the current tick remainder is to space / 2
        int24 nearestTick = (currentTick % space <= space / 2)
            ? currentTick - (currentTick % space)
            : currentTick + (space - (currentTick % space));
        // Changes direction back
        nearestTick *= direction;

        return nearestTick;
    }

    // /**
    //    * @dev add liquidity to the pool
    //    * @param amount0ToAdd Amount of token0 to add
    //    * @param amount1ToAdd Amount of token1 to add
    //    * @param fee_ Pool fee to locate the pool
    //    * @return tokenId Token id of the position
    //    * @return liquidity Amount of liquidity minted
    //    * @return amount0 Amount of token0 added
    //    * @return amount1 Amount of token1 added

    // **/
    // function mintNewPosition(
    //     uint amount0ToAdd,
    //     uint amount1ToAdd,
    //     uint24 fee_
    // )
    //     internal
    //     returns (uint tokenId, uint128 liquidity, uint amount0, uint amount1)
    // {
    //     address _sender = msg.sender;
    //     IUniswapV3Pool pool = IUniswapV3Pool(
    //         factory.getPool(token0, token1, fee_)
    //     );
    //     require(address(pool) != address(0), "pool not found");
    //     // Get the tick spacing of the pool
    //     int24 tikSpacing = pool.tickSpacing();
    //     (, int24 tick, , , , , ) = pool.slot0();

    //     // Approve the tokens
    //     IERC20(token0).approve(
    //         address(nonfungiblePositionManager),
    //         amount0ToAdd
    //     );
    //     IERC20(token1).approve(
    //         address(nonfungiblePositionManager),
    //         amount1ToAdd
    //     );
    //     // Minting the position
    //     INonfungiblePositionManager.MintParams
    //         memory params = INonfungiblePositionManager.MintParams({
    //             token0: token0,
    //             token1: token1,
    //             fee: fee_,
    //             tickLower: getNearestTick(tick, tikSpacing) - tikSpacing * 2,
    //             tickUpper: getNearestTick(tick, tikSpacing) + tikSpacing * 2,
    //             amount0Desired: amount0ToAdd,
    //             amount1Desired: amount1ToAdd,
    //             amount0Min: 0,
    //             amount1Min: 0,
    //             recipient: _sender,
    //             deadline: block.timestamp
    //         });
    //     //
    //     (tokenId, liquidity, amount0, amount1) = nonfungiblePositionManager
    //         .mint(params);
    //     // Refund the remaining tokens
    //     if (amount0 < amount0ToAdd) {
    //         IERC20(token0).approve(address(nonfungiblePositionManager), 0);
    //         uint refund0 = amount0ToAdd - amount0;
    //         IERC20(token0).transfer(_sender, refund0);
    //     }
    //     // Refund the remaining tokens
    //     if (amount1 < amount1ToAdd) {
    //         IERC20(token1).approve(address(nonfungiblePositionManager), 0);
    //         uint refund1 = amount1ToAdd - amount1;
    //         IERC20(token1).transfer(_sender, refund1);
    //     }
    // }

    // /**
    //  * @dev collectAllFees Collects all fees from the position
    //  * @param tokenId Token id of the position
    //  * @return amount0 Amount of token0 added
    //  * @return amount1 Amount of token1 added
    //  **/

    // function collectAllFees(
    //     uint tokenId
    // ) internal returns (uint amount0, uint amount1) {
    //     INonfungiblePositionManager.CollectParams
    //         memory params = INonfungiblePositionManager.CollectParams({
    //             tokenId: tokenId,
    //             recipient: address(this),
    //             amount0Max: type(uint128).max,
    //             amount1Max: type(uint128).max
    //         });

    //     (amount0, amount1) = nonfungiblePositionManager.collect(params);
    // }

    // /**
    //  * @dev increaseLiquidityCurrentRange  Increase liquidity in the current range
    //  * @param tokenId Token id of the position
    //  * @param amount0ToAdd Amount of token0 to add
    //  * @param amount1ToAdd Amount of token1 to add
    //  * @return liquidity Amount of liquidity minted
    //  * @return amount0 Amount of token0 added
    //  * @return amount1 Amount of token1 added
    //  **/
    // function increaseLiquidityCurrentRange(
    //     uint tokenId,
    //     uint amount0ToAdd,
    //     uint amount1ToAdd
    // ) internal returns (uint128 liquidity, uint amount0, uint amount1) {
    //     IERC20(token0).approve(
    //         address(nonfungiblePositionManager),
    //         amount0ToAdd
    //     );
    //     IERC20(token1).approve(
    //         address(nonfungiblePositionManager),
    //         amount1ToAdd
    //     );

    //     INonfungiblePositionManager.IncreaseLiquidityParams
    //         memory params = INonfungiblePositionManager
    //             .IncreaseLiquidityParams({
    //                 tokenId: tokenId,
    //                 amount0Desired: amount0ToAdd,
    //                 amount1Desired: amount1ToAdd,
    //                 amount0Min: 0,
    //                 amount1Min: 0,
    //                 deadline: block.timestamp
    //             });

    //     (liquidity, amount0, amount1) = nonfungiblePositionManager
    //         .increaseLiquidity(params);
    // }

    // /**
    //  * @dev decreaseLiquidityCurrentRange  Decrease liquidity in the current range
    //  * @param tokenId Token id of the position
    //  * @param liquidity Amount of liquidity to remove
    //  * @return amount0 Amount of token0 added
    //  * @return amount1 Amount of token1 added
    //  **/
    // function decreaseLiquidityCurrentRange(
    //     uint tokenId,
    //     uint128 liquidity
    // ) internal returns (uint amount0, uint amount1) {
    //     INonfungiblePositionManager.DecreaseLiquidityParams
    //         memory params = INonfungiblePositionManager
    //             .DecreaseLiquidityParams({
    //                 tokenId: tokenId,
    //                 liquidity: liquidity,
    //                 amount0Min: 0,
    //                 amount1Min: 0,
    //                 deadline: block.timestamp
    //             });

    //     (amount0, amount1) = nonfungiblePositionManager.decreaseLiquidity(
    //         params
    //     );
    // }

    /**
        * @dev swapExactInputSingleHop & swapExactInputSingleHopToRecipient swap exact input single hop
        * @param tokenIn Token to swap
        * @param tokenOut Token to receive
        * @param poolFee Pool fee
        * @param amountIn Amount of token to swap

        * @return amountOut Amount of token received

    **/

    // 直接使用合约内的 token进行交易，日常刷量使用
    function swapExactInputSingleHop(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint amountIn
    ) internal returns (uint amountOut) {
        // IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 10,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = router.exactInputSingle(params);
        //        IERC20(tokenOut).transfer(msg.sender, amountOut);
    }

    // 从user钱包转入代币 swap ，结束再转出代币到 user 钱包
    function swapExactInputSingleHopToRecipient(
        address tokenIn,
        address tokenOut,
        uint24 poolFee,
        uint amountIn
    ) internal returns (uint amountOut) {
        // 如果是 BNB 输入
        if (tokenIn == WBNB && msg.value > 0) {
            require(msg.value == amountIn, "BNB amount must match amountIn");
            // 不需要 transferFrom，直接使用 msg.value
        } else {
            // ERC-20 代币，从用户转入
            IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
            IERC20(tokenIn).approve(address(router), amountIn);
        }

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: tokenIn,
                tokenOut: tokenOut,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp + 10,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        if (tokenIn == WBNB) {
            amountOut = router.exactInputSingle{value: amountIn}(params);
        } else {
            amountOut = router.exactInputSingle(params);
        }

        // 如果输出是 WBNB，解包为 BNB 并发送给用户
        if (tokenOut == WBNB) {
            IWBNB(WBNB).withdraw(amountOut); // 解包 WBNB 为 BNB
            payable(msg.sender).transfer(amountOut); // 发送 BNB 给用户
        } else {
            IERC20(tokenOut).transfer(msg.sender, amountOut);
        }
    }
}
