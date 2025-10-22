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
volatile unsigned long t;
volatile bool rewardArmed = false;
volatile bool leftBlock = false;
volatile bool rightBlock = false;
volatile bool leftPort = false;
volatile bool rightPort = false;
volatile bool decide = false; 
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
      case 2: // Left-Only
        Serial.print(t);
        Serial.println(" gostate = 2");
        trialStart = t;
        rightBlock = true;
        break;
      case 3: // Decision-zone
        Serial.print(t);
        Serial.println(" gostate = 3");
        rewardArmed = true;
        decide = false;
        break;
      case 5: // Right-Only
        Serial.print(t);
        Serial.println(" gostate = 5");
        trialStart = t;
        leftBlock = true;
        break;
      case 6:
        Serial.print(t);
        Serial.println(" gostate = 6");
        rewardArmed = false;
        break;
      case 1: // manual reward triggered
        manualReward = true;
        decide = true;
        break;
      case 7: // white decision zone entry
        Serial.print(t);
        Serial.println(" gostate = 7");   
        break; 
      case 8: // black decision zone entry
        Serial.print(t);
        Serial.println(" gostate = 8");   
        break;            
      case 10: // manual Left
        manualReward = true;
        leftPort = true;
        break;
      case 11: // manual Right
        manualReward = true;
        rightPort = true;
        break;        
    }
  }

  
  sensorStateL_new = digitalRead(capSenseInL);
  sensorStateR_new = digitalRead(capSenseInR);
  t = millis();
  if (sensorStateL_new == HIGH && sensorStateL_prev == LOW) {
      // lick occured on left
      Serial.print(t);
      Serial.println(" left lick!");
      if (rewardArmed == true && leftBlock == false && decide == false) {
        Serial.print(t);
        Serial.println(" left reward triggered!");
        digitalWrite(waterValveConL,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConL,HIGH);
        rewardArmed = false;
        decide = true; 
        rightBlock = false;
      } 
}if (sensorStateR_new == HIGH && sensorStateR_prev == LOW) {
      // lick occured on right
      Serial.print(t);
      Serial.println(" right lick!");
      if (rewardArmed == true && rightBlock == false && decide == false) {
        Serial.print(t);
        Serial.println(" right reward triggered!");
        digitalWrite(waterValveConR,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConR,HIGH);
        rewardArmed = false;
        decide = true; 
        leftBlock = false;
      }
}else if (manualReward == true) {
        Serial.print(t);
        if(rightBlock == true){ 
        Serial.println(" left manually rewarded!");
        digitalWrite(waterValveConL,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConL,HIGH);}
        else if(leftBlock == true){
        Serial.println(" right manually rewarded!");
        digitalWrite(waterValveConR,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConR,HIGH);}
        else if(leftPort == true){ 
        Serial.println(" left manually rewarded!");
        digitalWrite(waterValveConL,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConL,HIGH);
        leftPort = false;}
        else if(rightPort == true){
        Serial.println(" right manually rewarded!");
        digitalWrite(waterValveConR,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConR,HIGH);
        rightPort = false;}         
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
        manualReward = false;
        decide = true;
        }
  sensorStateL_prev = sensorStateL_new;
  sensorStateR_prev = sensorStateR_new;
  // print out the value you read:
  delay(1);        // delay in between reads for stability
                                              }
