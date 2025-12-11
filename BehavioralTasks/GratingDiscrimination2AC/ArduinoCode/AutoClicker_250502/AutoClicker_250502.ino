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
int cameraFrameIn = 9;
int interval = 1000;
volatile unsigned long endTime = 0;
volatile unsigned long lastFrameTime = 0;
volatile bool autoClicker = false;
volatile bool autoClickerOn = false;
volatile bool record = false;
volatile unsigned long Time;
volatile int cameraState_prev = LOW;
volatile int cameraState_new;
volatile unsigned long frameNumber = 0;
const int rewardTime = 80; //how long to open the valve for once reward is trigged in ms
const int frameRate = 10;
const int frameTime = 1000 / frameRate;

void setup() {
  // put your setup code here, to run once:
  pinMode(waterValveConA, OUTPUT);
  pinMode(waterValvePowA, OUTPUT);
  pinMode(cameraFrameIn, OUTPUT);
  digitalWrite(waterValvePowA, HIGH);
  digitalWrite(waterValveConA, HIGH);

  // initialize serial communication at 9600 bits per second:
  Serial.begin(9600);
  digitalWrite(waterValveConA, LOW);
  delay(rewardTime);
  digitalWrite(waterValveConA, HIGH);
  delay(rewardTime);
}
void loop() {
  // put your main code here, to run repeatedly
  cameraState_new = digitalRead(cameraFrameIn);
  int receivedMsg = Serial.read();
  Time = millis();

  switch (receivedMsg) {
    case 4: // gostate 0, Approach corridor
      autoClicker = true;
      break;
    case 9: // Left-Only
      autoClicker = false;
      break;
    case 10: 
      record = true;
      break;
    case 11:
      record = false;
      break;
  }
  if (record == true) { 
  if (Time >= lastFrameTime + frameTime) {
      lastFrameTime = Time;
      frameNumber = frameNumber + 1;
      Serial.println(frameNumber);
      digitalWrite(cameraFrameIn, HIGH);
      digitalWrite(cameraFrameIn, LOW);
  }
  
  }
  if (autoClicker == true) {
    if (Time - endTime > interval) {
      endTime = Time;
      digitalWrite(waterValveConA, LOW);
      autoClickerOn = true;
      interval = random(500, 3501);
    }
  }

  if (autoClickerOn == true) {
    if (Time > endTime + rewardTime) {
      digitalWrite(waterValveConA, HIGH);
      autoClickerOn = false;
    }
  }

  cameraState_prev = cameraState_new;
  delay(1);
}
