/*
  Altered from AnalogReadSerial
  
  AnalogReadSerial

  Reads an analog input on pin 0, prints the result to the Serial Monitor.
  Graphical representation is available using Serial Plotter (Tools > Serial Plotter menu).
  Attach the center pin of a potentiometer to pin A0, and the outside pins to +5V and ground.

  This example code is in the public domain.

  http://www.arduino.cc/en/Tutorial/AnalogReadSerial
*/
int waterValveConA = 12;
int waterValvePowA = 11;
int interval = 1000;
volatile unsigned long endTime = 0;
volatile bool autoClicker = false;
volatile unsigned long Time;
const int rewardTime = 80; //how long to open the valve for once reward is trigged in ms

void setup() {
  // put your setup code here, to run once:
  pinMode(waterValveConA, OUTPUT);
  pinMode(waterValvePowA, OUTPUT);
  digitalWrite(waterValvePowA, HIGH);
  digitalWrite(waterValveConA, HIGH);

  // initialize serial communication at 9600 bits per second:
  Serial.begin(9600);
        digitalWrite(waterValveConA,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConA,HIGH);
        delay(rewardTime);
}

void loop() {
  // put your main code here, to run repeatedly
    int receivedMsg = Serial.read();
    Time = millis();
    switch (receivedMsg) {
      case 4: // gostate 0, Approach corridor
        autoClicker = true;
        break;
      case 9: // Left-Only
        autoClicker = false;
        break;
  }

  if (autoClicker == true){
    if (Time - endTime > interval){
        endTime = Time;
        digitalWrite(waterValveConA,LOW);
        delay(rewardTime);
        digitalWrite(waterValveConA,HIGH);
        delay(rewardTime);
        interval = random(500, 3501);
        
    }}
 delay(1);
  }
