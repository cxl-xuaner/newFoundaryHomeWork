// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



contract bank {
  struct Node {
    address user;
    uint256 deposit;
    address next;  // 指向链表中的下一个节点
  }

  mapping(address => Node) public nodes;  // 存储用户信息的节点映射
  address public head;                    // 链表的头节点（存款最高的用户）
  uint256 public listSize;                // 链表中用户的数量
// orient true 代表存款，false代表取款
  function insertOrUpdateUser(address user, uint256 amount, bool orient) public {
      uint256 totalDeposit;

      // 检查用户是否已经存在
      if (nodes[user].user != address(0)) {
          // 将已有的存款金额与新存款金额相加
          if(orient){
              totalDeposit = nodes[user].deposit + amount;
          }else{
              totalDeposit = nodes[user].deposit - amount;
          }
          
          // 移除用户节点，以便重新插入
          removeUser(user);
      }

      // 创建或更新节点
      Node memory newNode = Node(user, totalDeposit, address(0));

      // 如果链表为空或新的总金额大于头节点的金额，将新节点设为头节点
      if (head == address(0) || totalDeposit > nodes[head].deposit) {
          newNode.next = head;
          head = user;
      } else {
          // 在链表中找到插入位置
          address current = head;
          // 直到Current节点的下一个节点金额小于totalDeposit时，循环停止，new节点插入到current节点的后面
          while (nodes[current].next != address(0) && nodes[nodes[current].next].deposit >= totalDeposit) {
              current = nodes[current].next;
          }
          // 插入新节点
          newNode.next = nodes[current].next;
          nodes[current].next = user;
      }

      // 更新节点映射
      nodes[user] = newNode;
      listSize++;
  }


  function removeUser(address user) internal {
    // 找到前一个节点
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
        // 否则，将用户移除并重新插入链表
        insertOrUpdateUser(msg.sender, amount, false);
    }
    return true;
  }

}
