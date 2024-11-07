// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract bank {

  struct Node {
    address user;
    uint256 deposit;
    address next;  // Point to the next node in the linked list.
  }

  mapping(address => Node) public nodes;  
  address public head;                    
  uint256 public listSize;                
// orient true deposit，false withdraw
  function insertOrUpdateUser(address user, uint256 amount, bool orient) internal {
    uint256 totalDeposit;

    if(orient){
        totalDeposit = nodes[user].deposit + amount;
    }else{
        totalDeposit = nodes[user].deposit - amount;
    }
    // if user is exist,remove it
    if (nodes[user].user != address(0)) {
        // 将已有的存款金额与新存款金额相加
        // 移除用户节点，以便重新插入
        removeUser(user);
    }

      Node memory newNode = Node(user, totalDeposit, address(0));

      if (head == address(0) || totalDeposit > nodes[head].deposit) {
          newNode.next = head;
          head = user;
      } else {
          // find correct position
          address current = head;
          // The loop stops until the amount of the next node of the Current node is less than the totalDeposit, 
        //   and the new node is inserted after the current node.
          while (nodes[current].next != address(0) && nodes[nodes[current].next].deposit >= totalDeposit) {
              current = nodes[current].next;
          }
          // insert new node
          newNode.next = nodes[current].next;
          nodes[current].next = user;
      }

      // update new node
      nodes[user] = newNode;
      listSize++;
  }


  function removeUser(address user) internal {
    // find pre node
    address prev = head;
    if (head == user) {
        head = nodes[head].next;
    } else {
        while (nodes[prev].next != user) {
            prev = nodes[prev].next;
        }
        nodes[prev].next = nodes[user].next;
    }
    delete nodes[user];
    listSize--;
  }

  function getTopUsers(uint256 k) public view returns (address[] memory) {
      require(k <= listSize, "k exceeds the number of users");
      address[] memory topUsers = new address[](k);
      address current = head;
      
      for (uint256 i = 0; i < k; i++) {
          topUsers[i] = current;
          current = nodes[current].next;
      }
      
      return topUsers;
  }

  receive() external payable {
        insertOrUpdateUser(msg.sender, msg.value, true);
  }

  function withdraw(uint256 amount) external returns(bool){
    uint deposit = nodes[msg.sender].deposit;
    require(amount<=address(this).balance,"bank:Insufficient balance");
    require(amount<=deposit,"user:Insufficient balance");
    (bool success, ) = payable(msg.sender).call{value:amount}("");
    require(success, "withdraw failed");
    if (deposit == amount) {
        removeUser(msg.sender);
    } else {
        insertOrUpdateUser(msg.sender, amount, false);
    }
    return true;
  }

}
