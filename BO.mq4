#include <hash.mqh>

const int CANDLE_INDEX = 4;
const int RISK_IN_PERCENT_PER_TRADE = 1;
const int ENTRY_OFFSET = 0;
const int MIN_DISTANCE_IN_PIPS = 0;
const int NO_ORDER_NEARBY = 0;
const int SL = 10;
const int TP = 30;
const int BE = 5;


double lows[200];
double highs[200];
int lowCounter = 0;
int highCounter = 0;
int prevOrdersHistoryTotal = 0;

double addPips(double price, int pips) {
   return price + pips * Point * getBrokerFactor();
}

int getBrokerFactor() {
   int factor = 1;
   if (Digits == 5 || Digits == 3) {
      factor = 10;
   }
   return factor;
}

bool isNewCandle() {
   static int BarsOnChart;

   if (Bars==BarsOnChart) {
      return false;
   }
   BarsOnChart=Bars;
   return true;
}

bool isLow() {
   bool isLow = false;
   double lowPlusDistance = addPips(Low[CANDLE_INDEX], MIN_DISTANCE_IN_PIPS);
   if (Low[CANDLE_INDEX-1] > Low[CANDLE_INDEX] && Low[CANDLE_INDEX-2] > Low[CANDLE_INDEX] && Low[CANDLE_INDEX-3] > Low[CANDLE_INDEX]
       && Low[CANDLE_INDEX+1] > Low[CANDLE_INDEX] && Low[CANDLE_INDEX+2] > Low[CANDLE_INDEX] && Low[CANDLE_INDEX+3] > Low[CANDLE_INDEX]
       && (lowPlusDistance <= High[CANDLE_INDEX-1] || lowPlusDistance <= High[CANDLE_INDEX-2] || lowPlusDistance <= High[CANDLE_INDEX-3])
       && (lowPlusDistance <= High[CANDLE_INDEX+1] || lowPlusDistance <= High[CANDLE_INDEX+2] || lowPlusDistance <= High[CANDLE_INDEX+3])
       //&& High[CANDLE_INDEX-1] > High[CANDLE_INDEX] && High[CANDLE_INDEX+1] > High[CANDLE_INDEX]
       //&& High[CANDLE_INDEX-1] > High[CANDLE_INDEX] && High[CANDLE_INDEX+1] > High[CANDLE_INDEX]
       //&& High[CANDLE_INDEX-2] > High[CANDLE_INDEX-1] && High[CANDLE_INDEX+2] > High[CANDLE_INDEX+1]
       //&& Low[CANDLE_INDEX-3] > Low[CANDLE_INDEX-2] && Low[CANDLE_INDEX+3] > Low[CANDLE_INDEX+2]
       ) {
       isLow = true;
   }
   return isLow;
}

void addLow(double low) {
   lows[lowCounter++] = low;
}

bool isHigh() {
   bool isHigh = false;
   double highPlusDistance = addPips(High[CANDLE_INDEX], -MIN_DISTANCE_IN_PIPS);
   if (High[CANDLE_INDEX-1] < High[CANDLE_INDEX] && High[CANDLE_INDEX-2] < High[CANDLE_INDEX] && High[CANDLE_INDEX-3] < High[CANDLE_INDEX]
       && High[CANDLE_INDEX+1] < High[CANDLE_INDEX] && High[CANDLE_INDEX+2] < High[CANDLE_INDEX] && High[CANDLE_INDEX+3] < High[CANDLE_INDEX]
       && (highPlusDistance >= Low[CANDLE_INDEX-1] || highPlusDistance >= Low[CANDLE_INDEX-2] || highPlusDistance >= Low[CANDLE_INDEX-3])
       && (highPlusDistance >= Low[CANDLE_INDEX+1] || highPlusDistance >= Low[CANDLE_INDEX+2] || highPlusDistance >= Low[CANDLE_INDEX+3])
       //&& Low[CANDLE_INDEX-1] < Low[CANDLE_INDEX] && Low[CANDLE_INDEX+1] < Low[CANDLE_INDEX]
       //&& Low[CANDLE_INDEX-2] < Low[CANDLE_INDEX-1] && Low[CANDLE_INDEX+2] < Low[CANDLE_INDEX+1]
       //&& Low[CANDLE_INDEX-1] < Low[CANDLE_INDEX] && Low[CANDLE_INDEX+1] < Low[CANDLE_INDEX]
       //&& High[CANDLE_INDEX-3] < High[CANDLE_INDEX-2] && High[CANDLE_INDEX+3] < High[CANDLE_INDEX+2]
       ) {
       isHigh = true;
   }
   return isHigh;
}

void addHigh(double high) {
   highs[highCounter++] = high;
}

bool equalsChartCurrency() {
   return OrderSymbol()==Symbol();
}

bool isBuyOpen() {
   return OrderType()==0;
}

bool isSellOpen() {
   return OrderType()==1;
}

bool isBuyInProfit(int pips) {
   return Bid>=(addPips(OrderOpenPrice(), pips));
}

bool isSellInProfit(int pips) {
   return Ask<=(addPips(OrderOpenPrice(), -pips));
}

bool isBuyBreakEven() {
   return OrderOpenPrice() <= OrderStopLoss();
}

bool isSellBreakEven() {
   return OrderOpenPrice() >= OrderStopLoss();
}

double getLots() {
   return AccountBalance() * RISK_IN_PERCENT_PER_TRADE / 10000;
}

bool isMovedSL(int pips) {
   return OrderStopLoss() == addPips(OrderOpenPrice(), pips);
}

bool hasCounterOrder(int ticket) {
   bool hasCounterOrder = false;
   for(int cnt=0; cnt<OrdersTotal(); cnt++) {
      if (OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES) && (OrderMagicNumber() == ticket)) {
         hasCounterOrder = true;
      }
   }
   for(cnt=0; cnt<OrdersHistoryTotal(); cnt++) {
      if (OrderSelect(cnt, SELECT_BY_POS, MODE_HISTORY) && (OrderMagicNumber() == ticket)) {
         hasCounterOrder = true;
      }
   }
   return hasCounterOrder;
}

bool isTakeProfitTicket() {
   return (StringFind(OrderComment(), "tp", 0) > -1);
}

bool existsSellOrderNearBy(double sellEntry) {
   bool existsSellOrderNearBy = false;
   double sBorderTop = addPips(sellEntry, NO_ORDER_NEARBY);
   double sBorderBottom = addPips(sellEntry, -NO_ORDER_NEARBY);
   for(int a=0; a<OrdersTotal(); a++) {
      OrderSelect(a, SELECT_BY_POS, MODE_TRADES);
      double sEntry = OrderOpenPrice();
      double sTp = OrderTakeProfit();
      if (sTp < sEntry && sEntry <= sBorderTop && sEntry >= sBorderBottom) {
         existsSellOrderNearBy = true;
         break;
      }
   }
   return existsSellOrderNearBy;
}

bool existsBuyOrderNearBy(double buyEntry) {
   bool existsBuyOrderNearBy = false;
   double bBorderTop = addPips(buyEntry, NO_ORDER_NEARBY);
   double bBorderBottom = addPips(buyEntry, -NO_ORDER_NEARBY);
   for(int b=0; b<OrdersTotal(); b++) {
      OrderSelect(b, SELECT_BY_POS, MODE_TRADES);
      double bEntry = OrderOpenPrice();
      double bTp = OrderTakeProfit();
      if (bTp > bEntry && bEntry <= bBorderTop && bEntry >= bBorderBottom) {
         existsBuyOrderNearBy = true;
         break;
      }
   }
   return existsBuyOrderNearBy;
}

void closeTicketWithMagicNumber(double magicNumber) {
   for(int x=0; x<OrdersTotal(); x++) {
      OrderSelect(x, SELECT_BY_POS, MODE_TRADES);
      if (OrderMagicNumber() == magicNumber) {
         OrderClose(OrderTicket(), OrderLots(), isBuyOpen() ? Bid : Ask, 100, clrNONE);
         break;
      }
   }
}

bool isBuyInProfitBy(int pips) {
   return Bid>=addPips(OrderOpenPrice(), pips);
}

bool isBreakEven() {
   return OrderStopLoss() == OrderOpenPrice();
}

bool isSellInProfitBy(int pips) {
   return Ask<=addPips(OrderOpenPrice(), -pips);
}

void OnInit() {
}

void OnTick() {
  
  // Collect highs and lows
  if (isNewCandle()) {
      double lowCandidate = Low[CANDLE_INDEX];
      double lots = getLots();
      int ticketNr;
      if (isLow()) {
         double sellEntry = addPips(lowCandidate, -ENTRY_OFFSET);
         if (!existsSellOrderNearBy(sellEntry)) {
            double sellSL = addPips(sellEntry, SL);
            double sellTP = addPips(sellEntry, -TP);
            ticketNr = OrderSend(Symbol(), OP_SELLSTOP, lots, sellEntry, 0, sellSL, sellTP, 0, 0, 0, clrNONE);
         }
      }
      
      double highCandidate = High[CANDLE_INDEX];
      if (isHigh()) {
         double buyEntry = addPips(highCandidate, ENTRY_OFFSET);
         if (!existsBuyOrderNearBy(buyEntry)) {
            double buySL = addPips(buyEntry, -SL);
            double buyTP = addPips(buyEntry, TP);
            ticketNr = OrderSend(Symbol(), OP_BUYSTOP, lots, buyEntry, 0, buySL, buyTP, 0, 0, 0, clrNONE);
         }
      }
  }
  
  // BE
  /*for(int icnt=0; icnt<OrdersTotal(); icnt++) {
      if (OrderSelect(icnt, SELECT_BY_POS, MODE_TRADES) && equalsChartCurrency() && (isBuyOpen() || isSellOpen())) {
         double orderOpenPrice = OrderOpenPrice();
         double orderLots = OrderLots();
         int orderTicket = OrderTicket();
         if (isBuyOpen()) {            
            // hedging
            if (Bid <= addPips(orderOpenPrice, -RISK) && !hasCounterOrder(orderTicket)) {
               lots = 2*orderLots;
               sellTP = addPips(orderOpenPrice, -RISK-TP);
               Print("Enter sell order for ticket " + orderTicket);
               int counterOrder = OrderSend(Symbol(), OP_SELLSTOP, NormalizeDouble(lots, 2), addPips(Bid, -2), 0, 0, addPips(Bid, -15), 0, orderTicket, 0, clrNONE);
               if (counterOrder == -1) {
                  Print("Close buy ticket " + orderTicket);
                  OrderClose(orderTicket, NormalizeDouble(orderLots, 2), Bid, 0, clrNONE);
               }
            }
            
            
         } else if (isSellOpen()) {
            // hedging
            if (Ask >= addPips(orderOpenPrice, RISK) && !hasCounterOrder(orderTicket)) {
               lots = 2*orderLots;
               buyTP = addPips(orderOpenPrice, RISK+TP);
               Print("Enter buy order for ticket " + orderTicket);
               counterOrder = OrderSend(Symbol(), OP_BUYSTOP, NormalizeDouble(lots, 2), addPips(Ask, 2), 0, 0, addPips(Bid, 15), 0, orderTicket, 0, clrNONE);
               if (counterOrder == -1) {
                  Print("Close sell ticket " + orderTicket);
                  OrderClose(orderTicket, NormalizeDouble(orderLots, 2), Ask, 0, clrNONE);
               }
            }
         }
      }
  }*/
  
  // Manage orders
  for(int icnt=0; icnt<OrdersTotal(); icnt++) {
      if (OrderSelect(icnt, SELECT_BY_POS, MODE_TRADES) && equalsChartCurrency()) {
         if (isBuyOpen()) {
            /*if (isBuyInProfit(1) && !isClosedHalf()) { // close half the lots
               Print("Closing half lots for buy ticket " + OrderTicket());
               OrderClose(OrderTicket(), NormalizeDouble(OrderLots()/2,2), Bid, 100, 0);
               addClosedHalf();
            } else */if (isBuyInProfitBy(BE) && !isBreakEven()) { // move SL to break even
               Print("Moving SL to break even for buy ticket " + OrderTicket());
               OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, clrNONE);
            }
         } else if (isSellOpen()) {
            /*if (isSellInProfit(1) && !isClosedHalf()) { // close half the lots
               Print("Closing half lots for sell ticket " + OrderTicket());
               OrderClose(OrderTicket(), NormalizeDouble(OrderLots()/2,2), Ask, 100, 0);
               addClosedHalf();
            } else */if (isSellInProfitBy(BE) && !isBreakEven()) { // move SL to break even
               Print("Moving SL to break even for sell ticket " + OrderTicket());
               OrderModify(OrderTicket(), OrderOpenPrice(), OrderOpenPrice(), OrderTakeProfit(), 0, clrNONE);
            }
         }
      }
  }
  
  // Monitor TP
  /*if (prevOrdersHistoryTotal != OrdersHistoryTotal()) {
      for (int c=prevOrdersHistoryTotal; c<OrdersHistoryTotal(); c++) {
         int historyTicket = OrderSelect(c, SELECT_BY_POS, MODE_HISTORY);
         if (historyTicket && equalsChartCurrency() && isTakeProfitTicket()) {
            Print("Found TP in history for ticket " + OrderTicket());
            int historyTicketMagicNumber = OrderMagicNumber();
            Print("History Ticket Magic Number: " + historyTicketMagicNumber);
            for(int counter=0; counter<OrdersTotal(); counter++) {
               if (OrderSelect(counter, SELECT_BY_POS, MODE_TRADES)) {
                  int presentTicket = OrderTicket();
                  Print("Present Ticket: " + presentTicket);
                  double presentTicketLots = OrderLots();
                  Print("Present Ticket Lots: " + presentTicketLots);
                  if (presentTicket == historyTicketMagicNumber) {
                     // tp > magic number > ticket number
                     Print("Closing present ticket " + presentTicket);
                     OrderClose(presentTicket, presentTicketLots, isBuyOpen() ? Bid : Ask, 100, clrNONE);
                     
                     // closed > magic number > ticket number
                     OrderSelect(presentTicket, SELECT_BY_TICKET, MODE_HISTORY);
                     int mn = OrderMagicNumber();
                     OrderSelect(mn, SELECT_BY_TICKET, MODE_TRADES);
                     OrderClose(OrderTicket(), OrderLots(), isBuyOpen() ? Bid : Ask, 100, clrNONE);
                     
                     // tp > ticket number > magic number
                     closeTicketWithMagicNumber(historyTicket);
                     
                  }
               }
            }
         }
      }
      prevOrdersHistoryTotal = OrdersHistoryTotal();
  }*/
 
}