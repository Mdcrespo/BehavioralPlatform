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
int capSenseInC = 8;
int waterValveConR = 12;
int capSensePow = 7;
int waterValveConL = 9;
int waterValvePow = 11;

volatile int sensorStateL_prev = LOW;
volatile int sensorStateL_new;
volatile int sensorStateR_prev = LOW;
volatile int sensorStateR_new;
volatile int sensorStateC_prev = LOW;
volatile int sensorStateC_new;
volatile int sensorState_change;
volatile unsigned long t;
volatile bool rewardArmed = false;
volatile bool leftPort = false;
volatile bool left = true;
volatile bool rightPort = false;
volatile bool right = true;
volatile bool decide = false; 
volatile unsigned long trialStart;
volatile int lickStatus;
const int rewardTime = 45; //how long to open the valve for once reward is trigged in ms
volatile bool manualReward = false;



// the setup routine runs once when you press reset:
void setup() {
  // set up input and output pins
  pinMode(capSenseInL, INPUT);
  pinMode(capSenseInR, INPUT);
  pinMode(capSenseInC, INPUT);
  pinMode(waterValveConL, OUTPUT);
  pinMode(waterValveConR, OUTPUT);
  pinMode(waterValvePow, OUTPUT);
  pinMode(capSensePow, OUTPUT);
  digitalWrite(waterValvePow, HIGH);
  digitalWrite(waterValveConL, HIGH);
  digitalWrite(waterValveConR, HIGH);
  digitalWrite(capSensePow, HIGH);
  
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
      case 3: // Reward-zone
        Serial.print(t);
        Serial.println(" gostate = 3");
        rewardArmed = true;
        decide = false;
        break;
      case 4: // go entry Motion Block
        Serial.print(t);
        Serial.println(" gostate = 4");   
        right = false;
        left = true;
        break; 
      case 5: // nogo entry Motion Block
        Serial.print(t);
        Serial.println(" gostate = 5");  
        right = false; 
        left = false;
        break;    
      case 6:
        Serial.print(t);
        Serial.println(" gostate = 6");
        rewardArmed = false;
        left = false;
        right = false;
        break;
      case 7: // go entry Color Block
        Serial.print(t);
        Serial.println(" gostate = 7");   
        right = true;
        left = false;
        break; 
      case 8: // nogo entry Color Block
        Serial.print(t);
        Serial.println(" gostate = 8");  
        right = false; 
        left = false;
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
  sensorStateC_new = digitalRead(capSenseInC);
  t = millis();
  if (sensorStateL_new == HIGH && sensorStateL_prev == LOW) {
      // lick occured on left
      Serial.print(t);
      Serial.println(" left lick!");
      if (rewardArmed == true && decide == false && left == true) {
        Serial.print(t);
        Serial.println(" left reward triggered!");
        digitalWrite(waterValveConL,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConL,HIGH);
        rewardArmed = false;
      } 
      decide = true; 
}if (sensorStateR_new == HIGH && sensorStateR_prev == LOW) {
      // lick occured on right
      Serial.print(t);
      Serial.println(" right lick!");
      if (rewardArmed == true && decide == false && right == true) {
        Serial.print(t);
        Serial.println(" right reward triggered!");
        digitalWrite(waterValveConR,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConR,HIGH);
        rewardArmed = false;
      }
      decide = true; 
}if (sensorStateC_new == HIGH && sensorStateC_prev == LOW) {
      // Trial Initiation Sensor Touched
      Serial.print(t);
      Serial.println(" Center Touch!");
}else if (manualReward == true) {
        Serial.print(t);
        if(leftPort == true){ 
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
  sensorStateC_prev = sensorStateC_new;
  // print out the value you read:
  delay(1);        // delay in between reads for stability
                                              }
