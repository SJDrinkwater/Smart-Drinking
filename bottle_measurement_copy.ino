#include <WiFiNINA.h>
#include <ThingSpeak.h>
#include <DFRobot_HX711.h>

char ssid[] = "vodafone8BDF64";      // Your Wi-Fi network SSID
char pass[] = "Scarthnick1!";        // Your Wi-Fi network password
unsigned long channelNumber = 2396033;          // Your ThingSpeak Channel ID
const char *writeAPIKey = "ESEA2D9XJZ30S276"; // Your ThingSpeak Write API Key
const char *readAPIKey = "GVXU5TUECX5L72Y4";  // Your ThingSpeak Read API Key

WiFiClient client;
// Store the last button state
const int weightSensorPin1 = A2; // Analog pin for the weight sensor
const int weightSensorPin2 = A3; // Analog pin for the weight sensor
int status = 0;

DFRobot_HX711 MyScale(weightSensorPin1, weightSensorPin2);

// Calibration factor based on known weight and sensor reading
float knownWeight = 221.0; // Known weight in grams
float sensorReading = -265.8; // Sensor reading corresponding to known weight
float calibrationFactor = knownWeight / sensorReading;

bool initialWeightObtained = false;
bool firstWeightObtained = false; // Flag to indicate if the first weight reading has been obtained
float zeroOffset = 0.0; // Declare zeroOffset here
float previousWeight = 0.0; // Declare previousWeight here

void setup() {
  Serial.begin(9600);

  ThingSpeak.begin(client); // Initialize ThingSpeak
  // Connect to Wi-Fi
  while (WiFi.begin(ssid, pass) != WL_CONNECTED) {
    Serial.println("Connecting to WiFi...");
    delay(1000);
  }
  Serial.println("Connected to WiFi");

  Serial.println("Zeroing scale...");

  // Perform the zeroing process at the beginning of the program
  float total = 0.0;
  int samples = 10;
  for (int i = 0; i < samples; i++) {
    total += MyScale.readWeight();
    delay(100); // Short delay between readings
  }
  zeroOffset = total / samples; // Average of the readings


  // Mark that the initial weight has been obtained
  initialWeightObtained = true;
  if (initialWeightObtained == true){
    Serial.print("Scale has been zeroed!, Please put your drink on the coaster\n"); // 
    
    float currentRawWeight = MyScale.readWeight();
    int currentActualWeightINT = currentRawWeight - zeroOffset;

    delay(7000);

    if (currentActualWeightINT != 0){
      float lastValueField1 = ThingSpeak.readFloatField(channelNumber, 1, readAPIKey);
      float currentActualWeight = currentRawWeight - zeroOffset;
      if (lastValueField1 == -1.00){
        for (int i = 0; i < 3 && -1 != 200; i++) {
          ThingSpeak.setField(1, currentActualWeight); // Set the value for Field 1 (actual weight)// Set the value for Field 2 (positive difference in weight)
          status = ThingSpeak.writeFields(channelNumber, writeAPIKey);

          if (status == 200) {
            Serial.println("Data sent to ThingSpeak successfully!");
          } else {
            Serial.println("Error sending data to ThingSpeak. Retrying...");
            delay(5000); // Delay for 5 seconds before retrying
          }
        }
      }
    }
    else{
      loop();
    }
  }
}

void loop() {

  // Get current raw weight
  float currentRawWeight = MyScale.readWeight();
  Serial.print("Current Raw Weight: ");
  Serial.println(currentRawWeight);

  // use zero offset to display genuine weight value
  float currentActualWeight = currentRawWeight - zeroOffset;
  Serial.print("Current Actual Weight: ");
  Serial.println(currentActualWeight);

  // Display the last value from ThingSpeak Field 2
  Serial.print("Last Value from ThingSpeak Field 2: ");
  float lastValueField1 = ThingSpeak.readFloatField(channelNumber, 1, readAPIKey);
  Serial.println(lastValueField1);
  
  delay(10000);

  float currentRawWeightRefresh = MyScale.readWeight();
  Serial.print("Current Raw Weight: ");
  Serial.println(currentRawWeightRefresh);

  // Calculate the actual weight
  float currentActualWeightRefresh = currentRawWeightRefresh - zeroOffset;
  Serial.print("Current Actual Weight: ");
  Serial.println(currentActualWeightRefresh);

  int intCurrentActualWeightRefresh = int(currentActualWeightRefresh);
  int intCurrentActualWeight = int(currentActualWeight);
  Serial.println(intCurrentActualWeightRefresh);
  Serial.println(intCurrentActualWeight);
  
  if (intCurrentActualWeightRefresh == intCurrentActualWeight) {
    Serial.println("if statement 1 passed");

    int intlastValueField1 = int(lastValueField1);
    
    if (intCurrentActualWeightRefresh > intlastValueField1){
        
        for (int i = 0; i < 3 && -1 != 200; i++) {
          ThingSpeak.setField(1, currentActualWeight); 
          status = ThingSpeak.writeFields(channelNumber, writeAPIKey);
          if (status == 200) {
            Serial.println("Data sent to ThingSpeak successfully!");
            break; // Exit the loop if data sent successfully
          } else {
            Serial.println("Error sending data to ThingSpeak. Retrying...");
            delay(5000); // Delay for 5 seconds before retrying
          }
        }
    }
    if (intCurrentActualWeightRefresh > 10){ // the weight of the bottle

      if (intCurrentActualWeightRefresh < intlastValueField1) {
        Serial.println("if statement 2 passed");
        
        float weightDifferencePositive = lastValueField1 - currentActualWeight;
        Serial.println(weightDifferencePositive);
        if (weightDifferencePositive > 2){
          for (int i = 0; i < 3 && -1 != 200; i++) {
            ThingSpeak.setField(1, currentActualWeight); 
            ThingSpeak.setField(2, weightDifferencePositive); 
            status = ThingSpeak.writeFields(channelNumber, writeAPIKey);
            if (status == 200) {
              Serial.println("Data sent to ThingSpeak successfully!");
              break; // Exit the loop if data sent successfully
            } else {
              Serial.println("Error sending data to ThingSpeak. Retrying...");
              delay(5000); // Delay for 5 seconds before retrying
            }
          }
        }
      }
    }
  } 
  delay(6000); 
}





