open Pervasives
open Random

let num_opponents = 3

type bidask = {
  bid: int;
  ask: int;
  spread: int;
}

type transaction = {
  timestamp : int;
  bidask: bidask;
  order_type : string; (* bid or ask *)
}

type orderbook = {
  transactions : transaction list;
  buys: int;
  sells: int
}

type t = {
  hidden_number : int;
  avg_buy_value : int;
  profit : int;
  cash : int;
  inventory : int; (* Total number of shares owned *)
  orderbook : orderbook;
}

(**ADD DOCS *)
let change_true_value (trader:t) (adj_percentage:int) (down_or_up:bool) =
  failwith "Unimplemented"



(**[init_trader unit] is an initial trader of type t. *)
let init_trader true_value =
  {hidden_number = true_value; avg_buy_value = 0; profit = 0; cash = 1000000; inventory = 0; 
   orderbook = {transactions = []; buys = 0; sells = 0}}


(**[get_curr_profit cash init_cash msell_price inventory] is the current 
   running profit of the trader. *)
let get_curr_profit cash ?(init_cash = 1000000) msell_price inventory =
  inventory * msell_price + cash - init_cash

(**[make_bidask bid ask] is a type bidask that takes in a bid and ask value. *)
let make_bidask bid ask =
  {
    bid = bid;
    ask = ask;
    spread = ask - bid;
  }
(**[make_transaction timestamp bid ask order_type] is a type transaction that takes in a [timestamp], [order_type] and a [bid] and [ask]. *)
let make_transaction timestamp bid ask order_type =
  {
    timestamp = timestamp;
    bidask = (make_bidask bid ask);
    order_type = order_type;
  }

(**[make_sell trader transaction] is an option either of Some new type t trader (or the old 
   trader depending on whether the trader will accept the marketmaker's bid 
   for the security) or None which indicates whether trade was accepted. *)
let make_trade trader transaction =
  let sell_value = transaction.bidask.bid in
  let buy_value = transaction.bidask.ask in
  let inv = trader.inventory in 
  let book = trader.orderbook.transactions in
  let avg_val = trader.avg_buy_value in
  if trader.orderbook.buys = 0 then 
    if buy_value < trader.hidden_number then
      let new_buys = trader.orderbook.buys + 1 in
      let new_sells = trader.orderbook.sells in 
      let new_cash = trader.cash - buy_value in
      let newtransaction = {
        transaction with order_type = "bid"
      } in
      let t = {trader with avg_buy_value = 
                             (avg_val* (new_buys - 1) + buy_value) / new_buys; 
                           profit = (get_curr_profit new_cash sell_value inv+1); 
                           inventory = inv - 1; 
                           orderbook = {transactions = newtransaction::book; 
                                        buys = new_buys; sells = new_sells}} in
      Some (t, "hit")
    else None
  else if sell_value > avg_val && inv > 3 then
    let new_buys = trader.orderbook.buys in
    let new_sells = trader.orderbook.sells + 1 in 
    let new_cash = trader.cash + sell_value in
    let newtransaction = {
      transaction with order_type = "ask"
    } in
    let t = {trader with profit = (get_curr_profit new_cash sell_value inv-1); 
                         inventory = inv + 1; 
                         orderbook = {transactions = newtransaction::book; 
                                      buys = new_buys; sells = new_sells}} in 
    Some (t, "lift")
  else if buy_value < avg_val && trader.cash > buy_value then 
    let new_buys = trader.orderbook.buys + 1 in
    let new_sells = trader.orderbook.sells in 
    let new_cash = trader.cash - buy_value in
    let newtransaction = {
      transaction with order_type = "bid"
    } in
    let t = {trader with avg_buy_value = (avg_val + buy_value) / new_buys; 
                         profit = (get_curr_profit new_cash sell_value inv+1); 
                         inventory = inv - 1; 
                         orderbook = {transactions = newtransaction::book; 
                                      buys = new_buys; sells = new_sells}} in
    Some (t, "hit")
  else None


let make_trade_dumb (trader:t) (transaction:transaction) = 
  if float_of_int transaction.bidask.bid > (float_of_int num_opponents)*.3.5 +. (float_of_int trader.hidden_number) then 
    Some(trader, "hit")
  else if float_of_int transaction.bidask.ask < (float_of_int num_opponents)*.3.5 +. (float_of_int trader.hidden_number) then
    Some (trader, "lift")
  else
    None


(**[make_trade_dumb2 t transaction] is an option of None or Some pair of dummy 
   type t [trader] and a string denoting whether the trader will lift or hit. *)
let make_trade_dumb2 (trader:t) (transaction:transaction) = 
  let time = Random.int 2 in 
  let seed = (time) mod 2 in 
  if (abs (transaction.bidask.ask - trader.hidden_number) < 10) &&
     (abs (transaction.bidask.bid - trader.hidden_number) < 10 ) then
    match seed with
    | 0 -> Some (trader, "hit")
    | 1 -> Some (trader, "lift")
  else 
  if transaction.bidask.ask < trader.hidden_number + 10 
  then Some (trader, "lift")
  else if transaction.bidask.bid > trader.hidden_number - 10
  then Some (trader, "hit")
  else None



(**[get_final_profit trader] is the profit of the trader type t at the end 
   of the game. *)
let get_final_profit trader =
  trader.profit + (trader.inventory * trader.hidden_number)