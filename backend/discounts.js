const rewards = {
 r1: {name: 'ส่วนลด 20 บาท (ทุกเกม)', cost: 200, amount: 2000, percent: 0, minimum: 0},
 r2: {name: 'ส่วนลด 50 บาท (ขั้นต่ำ ฿300)', cost: 450, amount: 5000, percent: 0, minimum: 30000},
 r3: {name: 'คูปองลด 5% ไม่จำกัดยอด', cost: 800, amount: 0, percent: 5, minimum: 0},
 r4: {name: 'ส่วนลด 150 บาท (ขั้นต่ำ ฿1,000)', cost: 1500, amount: 15000, percent: 0, minimum: 100000}
};
function calculate(price, balance, useCoins, coupon, method) {
 const rates = {qr: 0, wallet: 100, card: 250};
 if (!Object.hasOwn(rates, method)) throw new Error('Invalid payment method');
 if (!Number.isSafeInteger(price) || price < 0) throw new Error('Invalid price');
 if (coupon && price < coupon.minimum_satang) throw new Error('Coupon minimum not met');
 const discount = coupon ? Math.min(price, coupon.percent > 0
   ? Math.floor(price * coupon.percent / 100) : coupon.amount_satang) : 0;
 const spent = useCoins ? Math.min(Math.max(0, balance), Math.floor((price-discount)/10)) : 0;
 const net = price-discount-spent*10;
 const fee = Math.round(net*rates[method]/10000);
 return {discount, spent, fee, total: net+fee, earned: Math.floor(net/1000)};
}
module.exports = {rewards, calculate};
