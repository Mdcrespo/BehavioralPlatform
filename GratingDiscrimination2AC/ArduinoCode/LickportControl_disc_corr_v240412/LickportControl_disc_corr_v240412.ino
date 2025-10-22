/*
  Altered from AnalogReadSerial
  
  AnalogReadSerial

  Reads an analog input on pin 0, prints the result to the Serial Monitor.
  Graphical representation is available using Serial Plotter (Tools > Serial Plotter menu).
  Attach the center pin of a potentiometer to pin A0, and the outside pins to +5V and ground.

  This example code is in the public domain.

  http://www.arduino.cc/en/Tutorial/AnalogReadSerial
*/
int capSenseInL = 13;
int capSenseInR = 10;
int waterValveConL = 12;
int waterValveConR = 9;
int waterValvePow = 11;

volatile int sensorStateL_prev = LOW;
volatile int sensorStateL_new;
volatile int sensorStateR_prev = LOW;
volatile int sensorStateR_new;
volatile int sensorState_change;
volatile int nXtra = 0;
volatile unsigned long t;
volatile bool rewardArmed = false;
volatile bool left = false;
volatile bool right = false;
volatile bool leftCorr = false;
volatile bool rightCorr = false;
volatile bool decide = false; 
volatile bool XLeft = false;
volatile bool XRight = false;
volatile unsigned long trialStart;
volatile int lickStatus;
const int rewardTime = 80; //how long to open the valve for once reward is trigged in ms
volatile bool manualReward = false;



// the setup routine runs once when you press reset:
void setup() {
  // set up input and output pins
  pinMode(capSenseInL, INPUT);
  pinMode(capSenseInR, INPUT);
  pinMode(waterValveConL, OUTPUT);
  pinMode(waterValveConR, OUTPUT);
  pinMode(waterValvePow, OUTPUT);
  digitalWrite(waterValvePow, HIGH);
  digitalWrite(waterValveConL, HIGH);
  digitalWrite(waterValveConR, HIGH);
  
  // initialize serial communication at 9600 bits per second:
  Serial.begin(9600);
}

// the loop routine runs over and over again forever:
void loop() {
  // for each loop check if there is a message to read on the Serial port
  if (Serial.available() > 0) {
    int receivedMsg = Serial.read();
    t = millis();
    switch (receivedMsg) {
      case 0: // gostate 0, Approach corridor
        Serial.print(t);
        Serial.println(" gostate = 0");
        break;
      case 2: // Left-trials
        Serial.print(t);
        Serial.println(" gostate = 2");
        trialStart = t;
        left = true;
        break;
      case 3: // reward-zone
        Serial.print(t);
        Serial.println(" gostate = 3");
        rewardArmed = true;
        decide = false;
        nXtra = 0;
        break;
      case 5: // Right-trials
        Serial.print(t);
        Serial.println(" gostate = 5");
        trialStart = t;
        right = true;
        break;
      case 6:
        Serial.print(t);
        Serial.println(" gostate = 6");
        rewardArmed = false;
        left = false;
        right = false;
        leftCorr = false;
        rightCorr = false;        
        break;
      case 1: // manual reward triggered
        manualReward = true;
        break;
      case 10:
        XLeft = true;
        break;
      case 11:
        XLeft = false;
        break;
      case 12:
        XRight = true;
        break;
      case 13:
        XRight = false;
        break;
    }
  }

  
  sensorStateL_new = digitalRead(capSenseInL);
  sensorStateR_new = digitalRead(capSenseInR);
  t = millis();
   if (XLeft == true && nXtra <3 && leftCorr == true) {
  rewardArmed = true;
  left = true;
  decide = false;
 }
  if (XRight == true && nXtra <3 && rightCorr == true) {
  rewardArmed = true;
  right = true;
  decide = false;
 }
  if (sensorStateL_new == HIGH && sensorStateL_prev == LOW) {
      // lick occured on left
      Serial.print(t);
      Serial.println(" left lick!");
      if (rewardArmed == true && left == true && decide == false) {
        Serial.print(t);
        Serial.println(" left reward triggered!");
        digitalWrite(waterValveConL,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConL,HIGH);
        leftCorr = true;
        rewardArmed = false;
        left = false;
        nXtra = nXtra + 1;
      }
      decide = true;     
}else if (sensorStateR_new == HIGH && sensorStateR_prev == LOW) {
      // lick occured on right
      Serial.print(t);
      Serial.println(" right lick!");
      if (rewardArmed == true && right == true && decide == false) {
        Serial.print(t);
        Serial.println(" right reward triggered!");
        digitalWrite(waterValveConR,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConR,HIGH);
        rightCorr = true;
        rewardArmed = false;
        right = false;
        nXtra = nXtra + 1;
      }
      decide = true;
}else if (manualReward == true) {
        Serial.print(t);
        if(left == true){ 
        Serial.println(" left manually rewarded!");
        digitalWrite(waterValveConL,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConL,HIGH);
        leftCorr = true;}
        else if(right == true){
        Serial.println(" right manually rewarded!");
        digitalWrite(waterValveConR,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConR,HIGH);
        rightCorr = true;}          
        else if( (t % 2) == 0) {
        Serial.println(" left manually rewarded!");
        digitalWrite(waterValveConL,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConL,HIGH);}
        else {
        Serial.println(" right manually rewarded!");
        digitalWrite(waterValveConR,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConR,HIGH);}
        nXtra = nXtra + 1;          
        manualReward = false;
        decide = true;
        }
  sensorStateL_prev = sensorStateL_new;
  sensorStateR_prev = sensorStateR_new;
  // print out the value you read:
  delay(1);        // delay in between reads for stability
                                              }
