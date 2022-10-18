// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./EIP712MetaTransaction.sol";

contract p2p is  EIP712MetaTransaction("p2p","1"){
    address payable owner;      //person deployed the contract

    event check(uint256 indexed _id);
    struct enter {
        address payable owner;
        uint256 low;
        uint256 high;
        uint256 deposite;
        uint256 price;
        bool active;
        uint256 id;
        string paymentoptions;
        uint256 orders;
        uint8 ordersmissed;
    }
   enter[] public ledger;  // ledger in enter by marchents
   
   constructor(){
   owner=payable(msg.sender);
   }

    function createenter(uint256 low,uint256 high,bool active,uint256 price,string memory paymentoptions) public payable{
        enter memory enter1;
        enter1.owner=payable(msg.sender);
        enter1.low=low;
        enter1.high=high;
        enter1.price=price;
        enter1.deposite=msg.value;
        enter1.active=active;
        enter1.id=ledger.length;
        enter1.paymentoptions=paymentoptions;
        ledger.push(enter1);
    }
    
    function getledger()public view returns(enter[] memory ledge) {
        return ledger;
    }

    function updateEnter(uint256 low,uint256 high,bool active,uint256 price,uint256 id,string memory paymentoptions) public payable{
        require(ledger[id].owner==msg.sender,"not owner");
        ledger[id].price=price;
        ledger[id].deposite+=msg.value;
        ledger[id].active=active;
        ledger[id].low=low;
        ledger[id].high=high;
        ledger[id].paymentoptions=paymentoptions;
    }

    function verfiythefaitreceived(uint256 orderid,bool sent) public{                      //called by merchent
        require(ledger[orders[orderid].enterid].owner==msg.sender,"you are not owner");
        if(sent == true){
            orders[orderid].respond=process.verfiyed;
        ledger[orders[orderid].enterid].deposite -=orders[orderid].amount;
        (orders[orderid].user).transfer(orders[orderid].amount);
        ledger[orders[orderid].enterid].orders++;

        }else{
        ledger[orders[orderid].enterid].deposite -=orders[orderid].amount;
        orders[orderid].respond=process.validatorsreview;
        orderstovalidate[ledger[orders[orderid].enterid].id].push(orderid);
         emit check(orderid);
        }
    }

   struct order{
       uint256 enterid;
       uint256 amount; // convert usd to eth
       address payable user;
       process  respond; 
       uint256 price;
       uint256 blocknumber;
   }

   order[] public orders;  // orderbook
   enum process{ tobereview, verfiyed,  validatorsreview ,invalidrequest}

   function paidedfiat(uint256 amount,uint id) public{                //called by the user one's the fait is payed ti the merchant
       require(ledger.length>id,"not enter");
       require(ledger[id].active==true," not active");
       require(ledger[id].deposite>=amount," higher amount");
       require((amount>=ledger[id].low)&&(amount<=ledger[id].high),"not in range");
    //    require(orderstovalidate[id].lenght==0,"can't pay now");
        order memory order1;
        order1.enterid=id;
        order1.amount=amount;
        order1.user=payable(msg.sender);
        order1.respond=process.tobereview;
        order1.blocknumber= block.number;
        order1.price=ledger[id].price;
        orders.push(order1);
   }

//       function relaypaided(uint256 amount,uint id) public{
//        require(ledger.length>id,"not enter");
//        require(ledger[id].active==true," not active");
//        require(ledger[id].deposite>=amount," higher amount");
//        require((amount>=ledger[id].low)&&(amount<=ledger[id].high),"not in range");
//        require(orderstovalidate[id]==0,"can't pay now");
//         order memory order1;
//         order1.enterid=id;
//         order1.amount=amount;
//         order1.owner=payable(msgSender());
//         order1.respond=process.tobereview;
//         order1.ordernumber= block.number;
//         order1.price=ledger[id].price;
//         orders.push(order1);
//    }


   function requestverification(uint256 orderid) public{                    //called by the user if the merchant hasn't responded the request
       require(orders.length>orderid,"doesn't exist");
       require(100 >=( block.number - orders[orderid].blocknumber),"can't apply for verfication");
       require(orders[orderid].respond==process.tobereview ,"already verfiyed");
        ledger[orders[orderid].enterid].deposite -=orders[orderid].amount;

       orderstovalidate[orders[orderid].enterid].push(orderid);
       orders[orderid].respond=process.validatorsreview;
   }
   //Vallidaters

   mapping(uint256=>uint256[])public orderstovalidate;
 

  function Govern(uint256 orderid,bool sent) public{
      uint256  k;
      uint256  i=0;
      uint256 positionoforderid;
      bool fa=false;
      require(msg.sender==owner,"not owner");
      for(k=0;k<orderstovalidate[orderid].length -1;k++){
        if(orderid==orderstovalidate[orders[orderid].enterid][k]){
          fa=true;
        }
      }
      require(
          fa=true,"not request");
        if(sent == true){
        orders[orderid].respond=process.verfiyed;
        (orders[orderid].user).transfer(orders[orderid].amount);
        ledger[orders[orderid].enterid].ordersmissed++;
        }else{
        orders[orderid].respond=process.invalidrequest;
        ledger[orders[orderid].enterid].deposite +=orders[orderid].amount;
        }
        while (positionoforderid<orderstovalidate[orderid].length-1) {
            orderstovalidate[orderid][i] = orderstovalidate[orderid][i+1];
            i++;
        }
        orderstovalidate[orders[orderid].enterid].pop;
  }

  function withdraw(uint256 orderId,uint256 amount)public{              //merchent to take out eth
      require(ledger[orderId].owner==msg.sender,"not owner");
      require(ledger[orderId].deposite>=amount,"no required amount");
    (ledger[orderId].owner).transfer(ledger[orderId].deposite);
  }

}
