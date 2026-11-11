const {test} = require('node:test');
const assert = require('node:assert/strict');
const {calculate} = require('../discounts');
test('all coins, partial coins, fees and coupon minimum', () => {
 assert.deepEqual(calculate(35000,2000,true,null,'qr'),{discount:0,spent:2000,fee:0,total:15000,earned:15});
 const coupon = {amount_satang:2000,percent:0,minimum_satang:0};
 assert.deepEqual(calculate(3500,2000,true,coupon,'card'),{discount:2000,spent:150,fee:0,total:0,earned:0});
 assert.equal(calculate(3500,9,true,null,'qr').total,3410);
 assert.equal(calculate(19900,0,false,{percent:5,minimum_satang:0},'wallet').total,19094);
 assert.throws(()=>calculate(29999,100,true,{minimum_satang:30000},'qr'));
 assert.throws(()=>calculate(3500,100,true,null,'invalid'));
});
