pragma circom 2.0.0;

/*This circuit template checks that c is the addition of a and b.*/

template Addition () {

   // Declaration of signals.
   signal input a;
   signal input b;
   signal output c;

   // Constraints.
   c <== a + b;
}
component main{public [b]} = Addition();