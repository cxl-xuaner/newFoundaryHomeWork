import {
  Cancel as CancelEvent,
  List as ListEvent,
  Sold as SoldEvent
} from "../generated/NFTMarketV3/NFTMarketV3"
import {
  Cancel,
  OrderBook,
  FiledOrder
} from "../generated/schema"

import { Bytes } from "@graphprotocol/graph-ts";

export function handleCancel(event: CancelEvent): void {
  let CancelEntity = FiledOrder.load(event.params.orderId);
  if(!CancelEntity){
    let entity = new Cancel(
      event.params.orderId
    )
    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash
  
    let sellOrderInfo = OrderBook.load(event.params.orderId)
    if(sellOrderInfo){
      sellOrderInfo.cancelTxHash = event.transaction.hash
      sellOrderInfo.save()
      
    }
  
    entity.save()

  }
 
}


export function handleList(event: ListEvent): void {
  let listEntity = OrderBook.load(event.params.orderId);
  if(!listEntity){
    let entity = new OrderBook(
      event.params.orderId
    )
    entity.id = event.params.orderId
    entity.nft = event.params.nft
    entity.tokenId = event.params.tokenId
    entity.seller = event.params.seller
    entity.payToken = event.params.payToken
    entity.price = event.params.price
    entity.deadline = event.params.deadline
  
    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash
    entity.cancelTxHash = Bytes.fromHexString("0x00") as Bytes;
    entity.filledTxHash = Bytes.fromHexString("0x00") as Bytes;

    entity.save()
  }
  
}

export function handleSold(event: SoldEvent): void {
  let SoldEntity = FiledOrder.load(event.params.orderId);
  if(!SoldEntity){
    let entity = new FiledOrder(
      event.params.orderId
    )
    entity.buyer = event.params.buyer
    entity.fee = event.params.fee
  
    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash
    let sellOrderInfo = OrderBook.load(event.params.orderId)
    if(sellOrderInfo){
      sellOrderInfo.filledTxHash = event.transaction.hash
      sellOrderInfo.save()
    }
    entity.save()
  }
  
  
}
