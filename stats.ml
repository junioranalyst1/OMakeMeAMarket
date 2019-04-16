open Pervasives
open String
open Trader
open Marketmaker
(* 
  *           STATISTICS ENGINE 
  *    - Gaussian Statistics
  *    - Three point Linear Square Regression Model 
  *    - Newton-Raphson Method for Curve approximation (Secant estimate)
  *
  *
  *
  *)
type graph_data = {bid_data : int list; ask_data : int list; trade_data : string list; time_data : int list; true_value : int}

(**[to_float_list_acc acc] is a list of floats from a string list. *)
let rec to_float_list_acc acc = function
  |[] -> acc
  |h::t -> to_float_list_acc ((float_of_string h):: acc) t 

(**[to_float_list lst] is a list of floats converted from the string list [lst] *)
let to_float_list lst =
  to_float_list_acc [] lst |> List.rev

(**[sum lst] is the sum of the floats in [lst] *)
let sum lst = (List.fold_left (fun acc h -> acc +. h) 0.0 lst)

(**[get_mean] is the mean of the values in lst. *)
let get_mean = function
  |[] -> failwith "empty list for getting mean"
  |lst -> sum lst /. float (List.length lst)

(**[sum_squared lst] is the sum of squares of the values in [lst]. *)
let sum_squared lst = 
  sum (List.map (fun x -> x*.x) lst)

(**[get_variance lst] is the variance of the values in [lst]. *)
let get_variance lst = 
  (* sum of the squared values divided by length subtracted by mean squared *)
  let mean = get_mean lst in
  (sum_squared lst)/. float (List.length lst) -. (mean *. mean)

(**[last_three_val] is a list of the last three values in the lst. *)
let rec last_three_val = function
  |[] -> failwith "empty list"
  |x::y::z::[] -> [float x; float y; float z]
  |h::t -> last_three_val t

(**[last_three_lsr lst] is the prediction of the next values based on the least 
   squares of the last three values in [lst].*)
let last_three_lsr lst =
  let three = last_three_val lst in 
  let x = sum three in 
  let x2 = sum_squared three in
  let length = float (List.length lst) in
  let last_ys = [length-. 2.0; length -.1.0; length] in 
  (* make a int list to float list function *)
  let y = sum last_ys in
  let xy = List.combine three last_ys |> 
           List.fold_left (fun acc (x,y) -> acc +. (x*.y)) 0.0 in
  let m = ((length *. xy) -. (x *.y))/.((length *. x2) -. (x *. x)) in
  let b = (y -. (m *.x))/.length in
  ((length +. 1.0) -. b) /. m


(** [newton_raphson_secant f start] approximates the root of a function [f] starting at seed value [start].
    Returns None if not converged or Some x where x is the converged value.  This approximates the derivative
    of the function as a secant line rather than the traditional tangent method *)
let newton_raphson_secant f start = 
  let dfdx fu =
    fun x -> (fu (x +. 0.1) -. fu x) /. 0.1 in
  let rec iter xk number =
    let update = start -. (f xk /. (dfdx f) xk) in 
    if number > 100 then None else 
    if (abs_float (update -. xk) < 0.01) then Some xk else iter xk (number + 1) in
  iter start 0

let rec get_max lst acc =
  match lst with
  | [] -> acc
  | h::t -> if h > (List.hd acc) then get_max t [h] else get_max t acc

let plot_data data =
  let xlength = List.length data.time_data in
  let ylen_est = get_max data.ask_data in 
  failwith "Unimplemented"


let rec get_data true_val bidask_lst bids asks trades times =
  match bidask_lst with
  | [] -> {bid_data = bids; ask_data = asks; trade_data = trades; time_data = times; true_value = true_val}
  | h::t -> get_data true_val t (h.bid::bids) (h.ask::asks) (h.trade_type::trades) times

let rec list_of_ints i n lst = 
  let x = i+1 in 
  if i <= n then list_of_ints x n (i::lst)
  else lst

let get_graph (market : Marketmaker.t) (trader : Trader.t) =
  let true_val = trader.true_value in
  let bidask_lst = market.bid_ask_history in
  let times = list_of_ints 0 (List.length bidask_lst) [] in 
  let bid_lst = [] in 
  let ask_lst = [] in 
  let trade = [] in 
  get_data true_val bidask_lst bid_lst ask_lst trade times


