// Shared coupon rules used by routes/coupons.js and routes/checkout.js.
// Money is handled in satang (1 baht = 100 satang) so there are no rounding errors.

// Rewards that can be bought with coins. Each one gives the user a coupon from the `coupons` table.
const rewards = {
    r1: { code: 'REWARD20', cost: 200 },
    r2: { code: 'REWARD50', cost: 450 },
    r3: { code: 'REWARD5P', cost: 800 },
    r4: { code: 'REWARD150', cost: 1500 }
};

// Reward coupons can only be bought with coins, not claimed by typing the code.
function isRewardCode(code) {
    return Object.values(rewards).some(reward => reward.code === code);
}

function toSatang(baht) {
    return Math.round(Number(baht) * 100);
}

// Returns an error message if the coupon can't be used right now, otherwise null.
// pendingUses = orders still waiting for approval that use this coupon.
function couponProblem(coupon, priceSatang, pendingUses = 0) {
    const now = new Date();

    if (Number(coupon.is_active) !== 1) return 'Coupon is not active';
    if (now < new Date(coupon.start_date)) return 'Coupon is not available yet';
    if (now > new Date(coupon.end_date)) return 'Coupon has expired';
    if (coupon.use_limit !== null && coupon.use_count + pendingUses >= coupon.use_limit) {
        return 'Coupon usage limit reached';
    }
    if (priceSatang < toSatang(coupon.min_order_amount)) return 'Coupon minimum not met';

    return null;
}

// Discount in satang for a package price in satang.
function couponDiscount(coupon, priceSatang) {
    let discount;

    if (coupon.discount_type === 'percent') {
        discount = Math.floor(priceSatang * Number(coupon.discount_value) / 100);
    } else {
        discount = toSatang(coupon.discount_value);
    }

    if (coupon.max_discount_amount !== null) {
        discount = Math.min(discount, toSatang(coupon.max_discount_amount));
    }

    return Math.max(0, Math.min(discount, priceSatang));
}

module.exports = { rewards, isRewardCode, toSatang, couponProblem, couponDiscount };
