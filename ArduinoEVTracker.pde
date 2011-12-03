/*
 * Web Server
 *
 * (Based on Ethernet's WebServer Example)
 *
 * A simple web server that shows the value of the analog input pins.
 */

#include "WiFly.h"
#include "Credentials.h"

//)))))))))))))))))))))) own code ((((((((((((((((((((((((((

int CorrectionVoltage =	85;
#define BATTERY		4		// Find the analog pin for the Battery. 





//)))))))))))))))))))))) own code ((((((((((((((((((((((((((

//lllllllllllllllllllll  from other code  llllllllllllllllllllllllllllllll

#include <Wire.h>		// <I2C.h>	

#define KPH_TO_MPH         0.0062137119223733
#define TIMEZONE           -6 // SDT, Cemtral



//// Check these::::::::::
#define BMA180PRESENT      1
#define ACCEL_INT          3
#define BMA180             0x40 //Accelerometer I2C address

// from here done not needed?
#define EE_W_MASK          0x10
#define MODE_CONFIG_MASK   0x03
#define BW_MASK            0xF0
#define RANGE_MASK         0x0E
#define LAT_INT_MASK       0x01
#define RESET_INT_MASK     0x40
#define HIGH_INT_MASK      0x20
#define LAT_INT            0x01
//#define GPS_add                0x29 //I2C GPS Shield I2C address


//############# GPRS Always on?? 
//#define GPRSSTATUS         5    //IO pin to check if powered on
//#define GPRSSWITCH         6    //IO pin to switch GPRS on/off
#define DTRPIN             8    //DTR pin for sleep mode on GPRS
#define SIMSIZE            30   //total storage space on SIM card

/*GPS variables*/
byte statusRegister;
//long latitude;
//long longitude;
long utcTime;
//long date;
long altitude;
long lastKnownLatitude;
long lastKnownLongitude;
long lastKnownUtcTime;
long lastKnownDate;
long lastKnownAltitude;
unsigned int course;
unsigned int speedKPH;
unsigned int lastKnownCourse;
unsigned int lastKnownSpeedKPH;


/*global variables*/
char Heading[3] = "";
char rxBuffer[200] = "";
char *defaultSMSAddress = "3163043397";  //default SMS address
char loopBack[40] = "";
char *str;

const char *pleaseCall = "Please Call";
const char *CMGR = "AT+CMGR=";
const char *CMGD = "AT+CMGD=";
const char *CPMS = "AT+CPMS?";
const char *CMGF = "AT+CMGF=1";
const char *CNMI = "AT+CNMI=0,0,0,0,0";
const char *CREG = "AT+CREG?";
const char *CSCLK = "AT+CSCLK=";
const char *CPOWD = "AT+CPOWD=1";
const char *googlePrefix = "http://maps.google.com/maps?q=";
const char *displayTimeDate = "+(";
const char *googleSuffix = ")&z=19"; //Google Earth full zoom
const char *displayHeading = "+MPH,";
const char *SecurityCodeNumber = "1572";  //security code used in SMS messages
const char *defaultEmailAddress = "PJMikols@mac.com"; //default email address

uint8_t registeredOnNetwork = 1;
uint8_t commandNumber = 0xFF;
uint8_t enableMotionDetection = 0;

volatile uint8_t ringIndicatorState = 0;
volatile uint8_t accelerometerState = 0;

byte initialPowerOn = 1;
byte alertMode = 0;


//__________________GPS 2 Globals ______________________


// The buffer size that will hold a GPS sentence. They tend to be 80 characters long
// so 90 is plenty.
#define BUFFSIZ 90 // plenty big

// global variables... From GPS sketch
char buffer[BUFFSIZ];        // string buffer for the sentence
char *parseptr;              // a character pointer for parsing
char buffidx;                // an indexer into the buffer

// The time, date, location data, etc.
uint8_t hour, minute, second, year, month, date;
uint32_t latitude, longitude;
uint8_t groundspeed, trackangle;
char latdir, longdir;
char status;











//lllllllllllllllllllll  from other code  llllllllllllllllllllllllllllllll

//~~~~~~~~~~~~~~~~~~~~~  SD_GPS SHIELD INCLUDE  ~~~~~~~~~~~~~~~~~~~~~~~~~
//

#include <SD.h>
#include <avr/sleep.h>
#include "GPSconfig.h"

// power saving modes
#define SLEEPDELAY 0
#define TURNOFFGPS 0
#define LOG_RMC_FIXONLY 0

// what to log
#define LOG_RMC 1 // RMC-Recommended Minimum Specific GNSS Data, message 103,04
#define LOG_GGA 0 // GGA-Global Positioning System Fixed Data, message 103,00
#define LOG_GLL 0 // GLL-Geographic Position-Latitude/Longitude, mesage 103,01
#define LOG_GSA 0 // GSA-GNSS DOP and Active Satellites, message 103,02
#define LOG_GSV 0 // GSV-GNSS Satellites in View, message 103,03
#define LOG_VTG 0 // VTG-Course Over Ground and Ground Speed, message 103,05

// NO SOFT SERIAL

// GPS RATE;  
#define GPSRATE 4800

    // GPS Buffer Size
#define BUFFSIZE 90


//char buffer[BUFFSIZE];
uint8_t bufferidx = 0;
uint8_t fix = 0; // current fix data
uint8_t i;
File logfile;




// Set the pins used 
#define powerPin 5
#define led1Pin 6
#define led2Pin 7
#define chipSelect 10





// read a Hex value and return the decimal equivalent
uint8_t parseHex(char c) {
  if (c < '0')
    return 0;
  if (c <= '9')
    return c - '0';
  if (c < 'A')
    return 0;
  if (c <= 'F')
    return (c - 'A')+10;
}




// blink out an error code
void error(uint8_t errno) {
/*
  if (SD.errorCode()) {
    putstring("SD error: ");
    Serial.print(card.errorCode(), HEX);
    Serial.print(',');
    Serial.println(card.errorData(), HEX);
  }
  */
  while(1) {
    for (i=0; i<errno; i++) {
      digitalWrite(led1Pin, HIGH);
      digitalWrite(led2Pin, HIGH);
      delay(100);
      digitalWrite(led1Pin, LOW);
      digitalWrite(led2Pin, LOW);
      delay(100);
    }
    for (; i<10; i++) {
      delay(200);
    }
  }
}


void sleep_sec(uint8_t x) {
  while (x--) {
     // set the WDT to wake us up!
    WDTCSR |= (1 << WDCE) | (1 << WDE); // enable watchdog & enable changing it
    WDTCSR = (1<< WDE) | (1 <<WDP2) | (1 << WDP1);
    WDTCSR |= (1<< WDIE);
    set_sleep_mode(SLEEP_MODE_PWR_DOWN);
    sleep_enable();
    sleep_mode();
    sleep_disable();
  }
}

SIGNAL(WDT_vect) {
  WDTCSR |= (1 << WDCE) | (1 << WDE);
  WDTCSR = 0;
}


//~~~~~~~~~~~~~~~~~~~~~  SD_GPS SHIELD INCLUDE  ~~~~~~~~~~~~~~~~~~~~~~~~~













Server server(80);


//// ----------------------  NEW SETUP  --------------------
//{
//initializeGPS();
////  pinMode(GPRSSTATUS,INPUT);
////  pinMode(GPRSSWITCH,OUTPUT);
////  digitalWrite(GPRSSWITCH,LOW);
//
//// Need this??? 
//// // /// ///  powerOnGPRS();
//  unsigned long timeOut = millis();
//  uint8_t index = 0;
//  
//  
//  // Checks and waits till the SIM is registered on network
//  while ( millis() <= timeOut + 10000)
//  {
//    if(Serial.available())
//    {
//      rxBuffer[index] = Serial.read();
//      index++;
//    }
//    if(strstr(rxBuffer,"Call Ready") != NULL)
//    {
//      break; //GPRS is registered on the network
//    }
//  }
//  
//  
//  delay(200);
//  Serial.flush();
//  initializeGPRS();
//  registeredOnNetwork = checkNetworkRegistration();
//  sendATCommand(CSCLK,rxBuffer,10,0,true);  //setup Sleep Mode 0
//
//
//// Need Ring Indicator??? Might be for Accel. Interupt. 
//  ringIndicatorState = 1;
//  attachInterrupt(0, ringIndicator, FALLING);
//
//
//  if(BMA180PRESENT)
//  {
//    initializeBMA();
//    attachInterrupt(1, movement, RISING);
//  }
// } 
//  
//// ----------------------  NEW SETUP  --------------------
  


//// ----------------------  NEW LOOP  --------------------
//  {
//    
//  if(enableMotionDetection)
//  {
//    activateMotionDetection();
//  }
//  if(accelerometerState)
//  {
//    accelerometerState = 0;
// //   powerOnGPRS();
//    unsigned long timeOut = millis();
//    uint8_t index = 0;
//    while ( millis() <= timeOut + 10000)
//    {
//      if(Serial.available())
//      {
//        rxBuffer[index] = Serial.read();
//        index++;
//      }
//      if(strstr(rxBuffer,"Call Ready") != NULL)
//      {
//        break; //GPRS is registered on the network
//      }
//    }
//    delay(200);
//    Serial.flush();
//    initializeGPRS();
//    Serial.flush();
//    alertMode = 1;
//    sendATCommand(CSCLK,rxBuffer,10,0,true);  //setup Sleep Mode 0
//    ringIndicatorState++;
//  }
//  if(!ringIndicatorState)
//  {
//    return;
//  }
//  registeredOnNetwork = checkNetworkRegistration();
//  if(registeredOnNetwork)
//  {
//    return; 
//  }
//  if(getGPSData()) //if satellite data is invalid, display last know coordinates
//  {
//    latitude = lastKnownLatitude;
//    longitude = lastKnownLongitude;
//    utcTime = lastKnownUtcTime;
//    date = lastKnownDate;  
//    course = lastKnownCourse;
//    speedKPH = lastKnownSpeedKPH;
//    altitude = lastKnownAltitude;
//  }
//  if(alertMode)
//  {
//    executeSMSCommand(99,rxBuffer,defaultSMSAddress,1);
//    alertMode = 0;
//    ringIndicatorState--;
//    return;
//  }
//  ringIndicatorState = 0;
//  sendATCommand(CPMS,rxBuffer,10,0,false);  //check for new messages
//  uint8_t unread = checkForMessages(rxBuffer);
//  if (unread > 0) //if there are unread messages stored on the SIM card then read them
//  { 
//    commandNumber = 0xFF;
//    uint8_t MessExec = 0; //number of messages successfully read
//    for (uint8_t lp = 0; lp < SIMSIZE; lp++) //loop no more than the total available on the sim card
//    { 
//      if(MessExec == unread) //finsh loop after last message read
//      { 
//        return;
//      }
//      sendATCommand(CMGR,rxBuffer,15,lp+1,true);  //read the message number (loop number + 1)
//      if(strlen(rxBuffer)<20) //blank message on SIM, move onto next memory location on sim card
//      {  
//        sendATCommand(CMGD,rxBuffer,15,lp+1,true);
//        MessExec++;  //increment if a message was read off the sim card
//        continue;
//      }
//      uint8_t replyMessageType = 0;
//      if(strstr(rxBuffer,pleaseCall)!=NULL) //if we don't see please call message is not a page
//      {
//        replyMessageType = 0; //loopback message type is a page
//      }
//      else if(strstr(rxBuffer,"@")!=NULL) //check to see if message is an email
//      {
//        replyMessageType = 2; //loopback message type is an email
//      }
//      else
//      {
//        replyMessageType = 1;  //loopback message type is an SMS
//      }
//      if(!SMSEmailPage(rxBuffer,SecurityCodeNumber,&commandNumber,replyMessageType)) //Message is an SMS
//      {
//        executeSMSCommand(commandNumber,rxBuffer,loopBack,replyMessageType);
//      }
//      sendATCommand(CMGD,rxBuffer,15,lp+1,true);
//      MessExec++;  //increment if a message was read off the sim card
//      continue;
//    }
//  }
//  if(initialPowerOn && BMA180PRESENT)
//  {
//    initialPowerOn = 0;
//    sendATCommand(CPOWD,rxBuffer,10,0,false);
//    delay(2000);
//    Serial.flush();
//  }
//  
//  
//  }
//  
//// ----------------------  NEW LOOP  --------------------  
  
  
  
  
  
  


void setup() {
  
  //............... Other tracker.......................
  //I2c.begin();
  Serial.begin(9600);
  //............... Other tracker.......................
  //~~~~~~~~~~~~~~~GPS_______________________________
   WDTCSR |= (1 << WDCE) | (1 << WDE);
  WDTCSR = 0;
  
  pinMode(led1Pin, OUTPUT);
  pinMode(led2Pin, OUTPUT);
  pinMode(powerPin, OUTPUT);
  
  
   digitalWrite(powerPin, LOW);

  // make sure that the default chip select pin is set to
  // output, even if you don't use it:
  pinMode(10, OUTPUT);
  
  
  // see if the card is present and can be initialized:
  if (!SD.begin(chipSelect)) {
    Serial.println("Card init. failed!");
    error(1);
  }
  
  // Makes/ Opens the next file, I think i want to just have 1 file, not sequential. 
  //................................
    strcpy(buffer, "GPSLOG00.TXT");
  for (i = 0; i < 100; i++) {
    buffer[6] = '0' + i/10;
    buffer[7] = '0' + i%10;
    // create if does not exist, do not open existing, write, sync after write
    if (! SD.exists(buffer)) {
      break;
    }
  }
  
  logfile = SD.open(buffer, FILE_WRITE);
  if( ! logfile ) {
    Serial.print("Couldnt create "); Serial.println(buffer);
    error(3);
  }
  Serial.print("Writing to "); Serial.println(buffer);
  
  
  //...................................

  // connect to the GPS at the desired rate
  Serial2.begin(GPSRATE);
  
  Serial.println("Ready!");
  
  Serial2.print(SERIAL_SET);
  delay(250);
  
        #if (LOG_DDM == 1)
             Serial2.print(DDM_ON);
        #else
             Serial2.print(DDM_OFF);
        #endif
          delay(250);
        #if (LOG_GGA == 1)
            Serial2.print(GGA_ON);
        #else
            Serial2.print(GGA_OFF);
        #endif
          delay(250);
        #if (LOG_GLL == 1)
            Serial2.print(GLL_ON);
        #else
            Serial2.print(GLL_OFF);
        #endif
          delay(250);
        #if (LOG_GSA == 1)
            Serial2.print(GSA_ON);
        #else
            Serial2.print(GSA_OFF);
        #endif
          delay(250);
        #if (LOG_GSV == 1)
            Serial2.print(GSV_ON);
        #else
            Serial2.print(GSV_OFF);
        #endif
          delay(250);
        #if (LOG_RMC == 1)
            Serial2.print(RMC_ON);
        #else
            Serial2.print(RMC_OFF);
        #endif
          delay(250);
        
        #if (LOG_VTG == 1)
            Serial2.print(VTG_ON);
        #else
            Serial2.print(VTG_OFF);
        #endif
          delay(250);
        
        #if (USE_WAAS == 1)
            Serial2.print(WAAS_ON);
        #else
            Serial2.print(WAAS_OFF);
        #endif 
        
        // ___________________ GPS 2 _________________________
        
          if (powerPin) {
    pinMode(powerPin, OUTPUT);
  }
  
  // Use the pin 13 LED as an indicator, Need to change??????
  pinMode(13, OUTPUT);
  
  // connect to the serial terminal at 9600 baud
 // Serial.begin(9600);
  
  // connect to the GPS at the desired rate
  Serial2.begin(GPSRATE);
   
  // prints title with ending line break 
  Serial.println("GPS parser"); 
 
   digitalWrite(powerPin, LOW);         // pull low to turn on!
        
        
        
        
        
        
        
        
        
        
        
  
   //~~~~~~~~~~~~~~~~~_______________________________
  WiFly.begin();

  if (!WiFly.join(ssid, passphrase)) {
    while (1) {
      // Hang on failure.
    }
  }

  
  Serial.println("\r\nItems installed:");
  Serial.println("\r\nGPSlogger");
  
  Serial.print("IP: ");
  Serial.println(WiFly.ip());
  
  server.begin();
}

void loop() {
  WIFI();
  GPS();

  
}

//######################  GPS  ########################################
void GPS()
{
  //Serial.println(Serial.available(), DEC);
  char c;
  uint8_t sum;

  // read one 'line'
  if (Serial2.available()) {
    c = Serial2.read();
    //Serial.print(c, BYTE);
    if (bufferidx == 0) {
      while (c != '$')
        c = Serial2.read(); // wait till we get a $
    }
    buffer[bufferidx] = c;

    //Serial.print(c, BYTE);
    if (c == '\n') {
      //putstring_nl("EOL");
      //Serial.print(buffer);
      buffer[bufferidx+1] = 0; // terminate it

      if (buffer[bufferidx-4] != '*') {
        // no checksum?
        Serial.print('*', BYTE);
        bufferidx = 0;
        return;
      }
      // get checksum
      sum = parseHex(buffer[bufferidx-3]) * 16;
      sum += parseHex(buffer[bufferidx-2]);

      // check checksum
      for (i=1; i < (bufferidx-4); i++) {
        sum ^= buffer[i];
      }
      if (sum != 0) {
        //putstring_nl("Cxsum mismatch");
        Serial.print('~', BYTE);
        bufferidx = 0;
        return;
      }
      // got good data!

      if (strstr(buffer, "GPRMC")) {
        // find out if we got a fix
        char *p = buffer;
        p = strchr(p, ',')+1;
        p = strchr(p, ',')+1;       // skip to 3rd item

        if (p[0] == 'V') {
          digitalWrite(led1Pin, LOW);
          fix = 0;
        } else {
          digitalWrite(led1Pin, HIGH);
          fix = 1;
        }
      }
      if (LOG_RMC_FIXONLY) {
        if (!fix) {
          Serial.print('_', BYTE);
          bufferidx = 0;
          return;
        }
      }
      // rad. lets log it!
      Serial.print(buffer);
      Serial.print('#', BYTE);
      digitalWrite(led2Pin, HIGH);      // sets the digital pin as output

      // Bill Greiman - need to write bufferidx + 1 bytes to getCR/LF
      bufferidx++;

      logfile.write((uint8_t *) buffer, bufferidx);
      logfile.flush();
      /*
      if( != bufferidx) {
         putstring_nl("can't write!");
         error(4);
      }
      */

      digitalWrite(led2Pin, LOW);

      bufferidx = 0;

      // turn off GPS module?
      if (TURNOFFGPS) {
        digitalWrite(powerPin, HIGH);
      }

      sleep_sec(SLEEPDELAY);
      digitalWrite(powerPin, LOW);
      return;
    }
    bufferidx++;
    if (bufferidx == BUFFSIZE-1) {
       Serial.print('!', BYTE);
       bufferidx = 0;
    }
  } else {

  }

}
void GPS2()
{
uint32_t tmp;
  
  Serial.print("\n\rRead: ");
  readline();
  
  // check if $GPRMC (global positioning fixed data)
  if (strncmp(buffer, "$GPRMC",6) == 0) {
    
    // hhmmss time data
    parseptr = buffer+7;
    tmp = parsedecimal(parseptr); 
    hour = tmp / 10000;
    minute = (tmp / 100) % 100;
    second = tmp % 100;
    
    parseptr = strchr(parseptr, ',') + 1;
    status = parseptr[0];
    parseptr += 2;
    
    // grab latitude & long data
    // latitude
    latitude = parsedecimal(parseptr);
    if (latitude != 0) {
      latitude *= 10000;
      parseptr = strchr(parseptr, '.')+1;
      latitude += parsedecimal(parseptr);
    }
    parseptr = strchr(parseptr, ',') + 1;
    // read latitude N/S data
    if (parseptr[0] != ',') {
      latdir = parseptr[0];
    }
    
    //Serial.println(latdir);
    
    // longitude
    parseptr = strchr(parseptr, ',')+1;
    longitude = parsedecimal(parseptr);
    if (longitude != 0) {
      longitude *= 10000;
      parseptr = strchr(parseptr, '.')+1;
      longitude += parsedecimal(parseptr);
    }
    parseptr = strchr(parseptr, ',')+1;
    // read longitude E/W data
    if (parseptr[0] != ',') {
      longdir = parseptr[0];
    }
    

    // groundspeed
    parseptr = strchr(parseptr, ',')+1;
    groundspeed = parsedecimal(parseptr);

    // track angle
    parseptr = strchr(parseptr, ',')+1;
    trackangle = parsedecimal(parseptr);


    // date
    parseptr = strchr(parseptr, ',')+1;
    tmp = parsedecimal(parseptr); 
    date = tmp / 10000;
    month = (tmp / 100) % 100;
    year = tmp % 100;
    
    Serial.print("\n\tTime: ");
    Serial.print(hour, DEC); Serial.print(':');
    Serial.print(minute, DEC); Serial.print(':');
    Serial.println(second, DEC);
    Serial.print("\tDate: ");
    Serial.print(month, DEC); Serial.print('/');
    Serial.print(date, DEC); Serial.print('/');
    Serial.println(year, DEC);
    
    Serial.print("\tLat: "); 
    if (latdir == 'N')
       Serial.print('+');
    else if (latdir == 'S')
       Serial.print('-');

    Serial.print(latitude/1000000, DEC); Serial.print("* ");
    Serial.print((latitude/10000)%100, DEC); Serial.print('\''); Serial.print(' ');
    Serial.print((latitude%10000)*6/1000, DEC); Serial.print('.');
    Serial.print(((latitude%10000)*6/10)%100, DEC); Serial.println('"');
   
    Serial.print("\tLong: ");
    if (longdir == 'E')
       Serial.print('+');
    else if (longdir == 'W')
       Serial.print('-');
    Serial.print(longitude/1000000, DEC); Serial.print("* ");
    Serial.print((longitude/10000)%100, DEC); Serial.print('\''); Serial.print(' ');
    Serial.print((longitude%10000)*6/1000, DEC); Serial.print('.');
    Serial.print(((longitude%10000)*6/10)%100, DEC); Serial.println('"');
   
  }
  //Serial.println(buffer);
}

uint32_t parsedecimal(char *str) {
  uint32_t d = 0;
  
  while (str[0] != 0) {
   if ((str[0] > '9') || (str[0] < '0'))
     return d;
   d *= 10;
   d += str[0] - '0';
   str++;
  }
  return d;
}

void readline(void) {
  char c;
  
  buffidx = 0; // start at begninning
  while (1) {
      c=Serial2.read();
      if (c == -1)
        continue;
      Serial.print(c);
      if (c == '\n')
        continue;
      if ((buffidx == BUFFSIZ-1) || (c == '\r')) {
        buffer[buffidx] = 0;
        return;
      }
      buffer[buffidx++]= c;
  }
}





//#######################  WIFI  #######################################


void WIFI ()
{
  Client client = server.available();
  if (client) {
    // an http request ends with a blank line
    boolean current_line_is_blank = true;
    while (client.connected()) {
      if (client.available()) {
        char c = client.read();
        // if we've gotten to the end of the line (received a newline
        // character) and the line is blank, the http request has ended,
        // so we can send a reply
        if (c == '\n' && current_line_is_blank) {
          // send a standard http response header
          client.println("HTTP/1.1 200 OK");
          client.println("Content-Type: text/html");
          client.println();
          
          // output the value of each analog input pin
          for (int i = 0; i < 6; i++) {
            client.print("analog input ");
            client.print(i);
            client.print(" is ");
            client.print(analogRead(i));
            client.println("<br />");
          }
          break;
        }
        if (c == '\n') {
          // we're starting a new line
          current_line_is_blank = true;
        } else if (c != '\r') {
          // we've gotten a character on the current line
          current_line_is_blank = false;
        }
      }
    }
    // give the web browser time to receive the data
    delay(100);
    client.stop();
  }
  
}


//#######################  Misc. Functiions.  ################################

void ringIndicator()
{
  ringIndicatorState++;
}

void movement()
{
  accelerometerState = 1;
}

/*This procedure will check if message is an SMS, if it is it will verify security code and will 
 log what the action is to be performed. The return value will dictate how the procedure was done
 return 1 - Message was successfully read and code was authorized, no commands found
 return 2 - Message was successfully read and code was authorized, command found
 return 3 - Message was successfully read and code was not authorized
 */

uint8_t SMSEmailPage(char *ptr,const char *_SecurityCodeNumber,uint8_t *_commandNumber,uint8_t _replyMessageType)
{
  if(_replyMessageType == 0) //message is a page
  {
    ptr = strtok_r(ptr,":",&str);
    ptr = strtok_r(NULL,"\n",&str);
    ptr = strtok_r(NULL,"\"",&str);
    ptr = strtok_r(NULL,"\"",&str);
    if(strncmp(ptr,_SecurityCodeNumber,4)!= 0)
    {
      return(1); //invalid security code
    }
    ptr[0] = '0';
    ptr[1] = '0';
    ptr[2] = '0';
    ptr[3] = '0';
    *_commandNumber = atoi(ptr);
    return(0);
  }
  if(_replyMessageType == 1) //message is an SMS
  {
    ptr = strtok_r(ptr,":",&str);
    ptr = strtok_r(NULL,"\"",&str);  //loopback
    ptr = strtok_r(NULL,"\"",&str);  //loopback
    ptr = strtok_r(NULL,"\"",&str);  //loopback
    ptr = strtok_r(NULL,"\"",&str);  //loopback
    if (strlen(ptr) < 40)  //if phone number is 39 digits or less then it's OK to use
    {
      strcpy(loopBack,ptr);
    }
    ptr = strtok_r(NULL,"\n",&str);
    ptr = strtok_r(NULL,":",&str);
    ptr = ptr + (strlen(ptr)-4);
    if(strncmp(ptr,SecurityCodeNumber,4)!= 0)
    {
      return(1); //invalid security code
    }
    ptr = strtok_r(NULL,":",&str);
    *_commandNumber = atoi(ptr);
    return(0);
  }
  if(_replyMessageType == 2) //message is an email
  {
    ptr = strtok_r(ptr,":",&str);
    ptr = strtok_r(NULL,"\n",&str); 
    ptr = strtok_r(NULL,"/",&str);
    if (strlen(ptr) < 40)  //if email address is 39 digits or less then it's OK to use
    {
      strcpy(loopBack,ptr);
    }
    for(uint8_t ws = 0; ws < strlen(loopBack); ws++)
    {
      if(loopBack[ws] == ' ')
      {
        loopBack[ws] = '\0';
      }
    }
    ptr = strtok_r(NULL,"/",&str);
    ptr = strtok_r(NULL,":",&str);
    ptr = ptr + (strlen(ptr)-4);
    if(strncmp(ptr,SecurityCodeNumber,4)!= 0)
    {
      return(1); //invalid security code
    }
    ptr = strtok_r(NULL,":",&str);
    *_commandNumber = atoi(ptr);
    return(0);
  }
}

uint8_t checkForMessages(char *ptr)
{
  uint8_t receivedMessages = 0;  //total unread messages stored on the SIM card
  ptr = strtok_r(ptr,",",&str);
  ptr = strtok_r(NULL,",",&str);
  receivedMessages = atoi(ptr);  //Number of messages on the sim card
  return(receivedMessages);
}

uint8_t initializeGPRS()
{
  sendATCommand(CMGF,rxBuffer,10,0,false);
  sendATCommand(CNMI,rxBuffer,10,0,false);
}

uint8_t checkNetworkRegistration()
{
  sendATCommand(CREG,rxBuffer,30,0,false);  //check network registration status
  if(strstr(rxBuffer,",1") != NULL || strstr(rxBuffer,",5") != NULL)
  {
    return(0); //GPRS is registered on the network
  }
  return(1); //GPRS is not registered on the network
}


//// Don't need, GSM ALWAYS ON
//
//uint8_t powerOnGPRS(){
//  if(digitalRead(GPRSSTATUS))
//  {
//    return(0); //GPRS is already powered on
//  } 
//  for(uint8_t i = 0; i < (RETRY+1);i++)
//  {
//    digitalWrite(GPRSSWITCH,HIGH); //send signal to turn on
//    delay(1100);  //signal needs to be low for 1 second to turn GPRS on
//    digitalWrite(GPRSSWITCH,LOW);
//    delay(2300);
//    if(digitalRead(GPRSSTATUS))
//    {
//      return(0); //GPRS powered on successfully
//    }
//  }
//  return(1); //the GPRS did not turn on
//}





/*uint8_t getGPSData()
{
  I2c.write(GPS_add,0x00); //set address pointer to zero
  delay(1); 
  I2c.read(GPS_add,31);
  statusRegister = I2c.receive();
  if(!bitRead(statusRegister,0))
  {
    return(1);
  }
  if(!bitRead(statusRegister,2))
  {
    return(2);
  }
  if(!bitRead(statusRegister,1))
  {
    return(3);
  }
  /*Data is valid so let's copy the current data into the 
  **last known data variables in case we loose satellite
  **acquisition. We now have the last known coordinates*/
/*  lastKnownLatitude = latitude;
  lastKnownLongitude = longitude;
  lastKnownUtcTime = utcTime;
  lastKnownDate = date;  
  lastKnownCourse = course;
  lastKnownSpeedKPH = speedKPH;
  lastKnownAltitude = altitude;
  /*There is valid satellite data so let's collect it*/
/*  for(uint8_t i = 0;i < 4;i++)
  { 
    latitude <<= 8;
    latitude |= I2c.receive();
  }
  for(uint8_t i = 0;i < 4;i++)
  {
    longitude <<= 8;
    longitude |= I2c.receive();
  }
  for(uint8_t i = 0;i < 4;i++)
  {
    utcTime <<= 8;
    utcTime |= I2c.receive();
  }
  utcTime /= 1000;
  long _hour = utcTime/10000;
  long _minutes = (utcTime - (_hour*10000))/100;
  long _seconds = utcTime - ((_hour*10000) + (_minutes * 100));
  _hour += TIMEZONE;
  if(_hour < 0)
  {
    _hour += 24;
  }
  utcTime = (_hour*10000) + (_minutes*100) + _seconds;
  for(uint8_t i = 0;i < 4;i++)
  {
    date <<= 8;
    date |= I2c.receive();
  }
  long _day = date/10000;
  long _month = (date - (_day*10000))/100;
  long _year = date - ((_day*10000) + (_month * 100));
  date = (_month*10000) + (_day*100) + _year;
 for(uint8_t i = 0;i < 2;i++)
  { 
    speedKPH <<= 8;
    speedKPH |= I2c.receive();
  }
  for(uint8_t i = 0;i < 2;i++)
  {
    course <<= 8;
    course |= I2c.receive();
  }
  for(uint8_t i = 0;i < 4;i++)
  {
    altitude <<= 8;
    altitude |= I2c.receive();
  }
  return(0);
}
*/

uint8_t initializeGPS()
{
  /*Enter code here if you want to change defaults*/
}

////NO Fuel Gauge... But could put the Voltage Monitor here...
//
//uint8_t initializeFuelGauge()
//{
//  uint8_t fgdata[2] = {0x40,0x00};
//  /*initiate a quick start*/
//  if(I2c.write(FUELGAUGE,0x06,fgdata,2))
//  {
//    return(1);
//  }
//  /*set interrupt value*/
//  if(I2c.write(FUELGAUGE,0x0C,0x97))
//  {
//    return(2);
//  }
//  return(0);
//}


//unsigned int getBatterySOC()
//{
//  unsigned int batterySOC = 0;
// I2c.read(FUELGAUGE,0x04,2);
// for(int i = 0;i < 2;i++){ 
//   batterySOC <<= 8;
//  batterySOC |= I2c.receive();
// }
//  return(map(batterySOC,0x0000,0x6400,0,10000));
// }

unsigned int getBatteryVoltage()
{
  unsigned int batteryVoltage = 0;
  
  // batteryVoltage= BATTERY* CorrectionVoltage
  
 // I2c.read(FUELGAUGE,0x02,2);
 // batteryVoltage = I2c.receive();
 // batteryVoltage <<= 8;
//  batteryVoltage |= I2c.receive();
//  batteryVoltage >>= 4;
  return(batteryVoltage);
}

uint8_t sendATCommand(const char *atCommand,char *buffer, int atTimeOut,int smsNumber,boolean YN)
{
  boolean atError = false;
  uint8_t index = 0;
  unsigned long timeOut = 0;
  Serial.flush();
  for (uint8_t SAT = 0; SAT < 3; SAT++)
  {
    atError = false;
    buffer[0] = '\0';
    index = 0;
    if (YN)
    {
      Serial.print(atCommand);
      Serial.println(smsNumber);
    }
    else 
    {
      Serial.println(atCommand);
    }
    timeOut = millis() + (1000*atTimeOut);
    while (millis() < timeOut)
    {
      if (Serial.available())
      {
        buffer[index] = Serial.read();
        index++;
        buffer[index] = '\0';
        if(strstr(buffer,"ERROR")!=NULL) //if there is an error send AT command again
        {
          atError = true;
          break;
        }
        if(strstr(buffer,"OK")!=NULL) //if there is no error then done
        {
          Serial.flush();
          return(0);
        }
        if (index == 198) //Buffer is full
        { 
          return(1);
        }
      }
    }
    if(atError)
    {
      continue;
    }
    Serial.println("AT");// DEBUG
    delay(500);// DEBUG
    Serial.flush();
    break;
  }
  return(2);
}

uint8_t executeSMSCommand(uint8_t _commandNumber,char *_rxBuffer,char *_replyBack, uint8_t _replyMessageType)
{
  unsigned long timeOut;
  byte ByteIn = 0;
  boolean ns = false;

  switch(_commandNumber){
  case 0:    
    {
      if(_replyMessageType == 0){
        _replyMessageType = 1;
        strcpy(_replyBack,defaultSMSAddress);
      }
      if(_replyMessageType == 1)
      {
        Serial.print("AT+CMGS=\"");
        Serial.print(_replyBack);
        Serial.println("\"");
      }
      else
      {
        Serial.println("AT+CMGS=\"500\"");
      }
      
      timeOut = millis();
      while (millis() < timeOut + 2000)
      {
        if(Serial.available())
        {
          if(Serial.read() == '>')
          {
            ns = true;
            break;
          }
        }
      }
      if(!ns)
      {
        Serial.println(0x1B,BYTE); //do not send message
        delay(500);
        Serial.flush();
        return(1);
      } //There was an error waiting for the > 
      if(_replyMessageType == 2)
      {
        Serial.println(_replyBack);
      } 
    }
    break;
  case 1:
    {  
      Serial.print("AT+CMGS=\"");
      Serial.print(defaultSMSAddress);
      Serial.println("\"");
      timeOut = millis();
      while (millis() < timeOut + 2000)
      {
        if(Serial.available())
        {
          if(Serial.read() == '>')
          {
            ns = true;
            break;
          }
        }
      }
      if(!ns)
      {
        Serial.println(0x1B,BYTE); //do not send message
        delay(500);
        Serial.flush();
        return(1); //There was an error waiting for the > 
      } 
    } 
    break;
  case 2:
    {
      Serial.println("AT+CMGS=\"500\"");
      timeOut = millis();
      while (millis() < timeOut + 2000)
      {
        if(Serial.available())
        {
          if(Serial.read() == '>')
          {
            ns = true;
            break;
          }
        }
      }
      if(!ns)
      {
        Serial.println(0x1B,BYTE); //do not send message
        delay(500);
        Serial.flush();
        return(1); //There was an error waiting for the >
      }  
      Serial.println(defaultEmailAddress);
    }
    break;
  case 3: //ACTIVATE SLEEP MODE
    {
      if(_replyMessageType == 0)
      {
        _replyMessageType = 1;
        strcpy(_replyBack,defaultSMSAddress);
      }
      if(_replyMessageType == 1)
      {
        Serial.print("AT+CMGS=\"");
        Serial.print(_replyBack);
        Serial.println("\"");
      }
      else
      {
        Serial.println("AT+CMGS=\"500\"");
      }
      
      timeOut = millis();
      while (millis() < timeOut + 2000)
      {
        if(Serial.available())
        {
          if(Serial.read() == '>')
          {
            ns = true;
            break;
          }
        }
      }
      if(!ns)
      {
        Serial.println(0x1B,BYTE); //do not send message
        delay(500);
        Serial.flush();
        return(1);
      } //There was an error waiting for the > 
      if(_replyMessageType == 2)
      {
        Serial.println(_replyBack);
      }
      Serial.print("SLEEP MODE ACTIVATED");
      Serial.println(0x1A,BYTE);
      uint8_t idx = 0;
      ns = false;
      timeOut = millis();
      while (millis() < timeOut + 60000)
      {
        if (Serial.available())
        {
          _rxBuffer[idx] = Serial.read();
          idx++;
          _rxBuffer[idx] = '\0';
          if(strstr(_rxBuffer,"ERROR")!= NULL)
          {
           // Serial.println("ERROR SENDING");
            delay(500);
            return(2);
          }
          if(strstr(_rxBuffer,"+CMGS:")!= NULL)
          {
            sendATCommand(CSCLK,rxBuffer,10,2,true);  //setup Sleep Mode 2
           // Serial.println("MESSAGE SENT");
            delay(500);
            return(0);
          }
        }
      }
      delay(500);
      Serial.flush();
      return(3);
    }
    break;
  case 4: //DEACTIVATE SLEEP MODE
    {
      if(_replyMessageType == 0)
      {
        _replyMessageType = 1;
        strcpy(_replyBack,defaultSMSAddress);
      }
      if(_replyMessageType == 1)
      {
        Serial.print("AT+CMGS=\"");
        Serial.print(_replyBack);
        Serial.println("\"");
      }
      else
      {
        Serial.println("AT+CMGS=\"500\"");
      }
      
      timeOut = millis();
      while (millis() < timeOut + 2000)
      {
        if(Serial.available())
        {
          if(Serial.read() == '>')
          {
            ns = true;
            break;
          }
        }
      }
      if(!ns)
      {
        Serial.println(0x1B,BYTE); //do not send message
        delay(500);
        Serial.flush();
        return(1);
      } //There was an error waiting for the > 
      if(_replyMessageType == 2)
      {
        Serial.println(_replyBack);
      }
      
      Serial.print("SLEEP MODE DEACTIVATED");
      Serial.println(0x1A,BYTE);
      uint8_t idx = 0;
      ns = false;
      timeOut = millis();
      while (millis() < timeOut + 60000)
      {
        if (Serial.available())
        {
          _rxBuffer[idx] = Serial.read();
          idx++;
          _rxBuffer[idx] = '\0';
          if(strstr(_rxBuffer,"ERROR")!= NULL)
          {
           // Serial.println("ERROR SENDING");
            delay(500);
            return(2);
          }
          if(strstr(_rxBuffer,"+CMGS:")!= NULL)
          {
            sendATCommand(CSCLK,rxBuffer,10,0,true);  //setup Sleep Mode 0
           // Serial.println("MESSAGE SENT");
            delay(500);
            return(0);
          }
        }
      }
      delay(500);
      Serial.flush();
      return(3);
    }
    break;
  case 5: //power down GPRS
    {
      if(_replyMessageType == 0)
      {
        _replyMessageType = 1;
        strcpy(_replyBack,defaultSMSAddress);
      }
      if(_replyMessageType == 1)
      {
        Serial.print("AT+CMGS=\"");
        Serial.print(_replyBack);
        Serial.println("\"");
      }
      else
      {
        Serial.println("AT+CMGS=\"500\"");
      }
      
      timeOut = millis();
      while (millis() < timeOut + 2000)
      {
        if(Serial.available())
        {
          if(Serial.read() == '>')
          {
            ns = true;
            break;
          }
        }
      }
      if(!ns)
      {
        Serial.println(0x1B,BYTE); //do not send message
        delay(500);
        Serial.flush();
        return(1);
      } //There was an error waiting for the > 
      if(_replyMessageType == 2)
      {
        Serial.println(_replyBack);
      }
      
      Serial.print("GPRS POWER DOWN");
      Serial.println(0x1A,BYTE);
      uint8_t idx = 0;
      ns = false;
      timeOut = millis();
      while (millis() < timeOut + 60000)
      {
        if (Serial.available())
        {
          _rxBuffer[idx] = Serial.read();
          idx++;
          _rxBuffer[idx] = '\0';
          if(strstr(_rxBuffer,"ERROR")!= NULL)
          {
           // Serial.println("ERROR SENDING");
            delay(500);
            return(2);
          }
          if(strstr(_rxBuffer,"+CMGS:")!= NULL)
          {
            sendATCommand(CMGD,rxBuffer,15,1,true);
            delay(2000);
            sendATCommand(CPOWD,rxBuffer,10,0,false);  //setup Sleep Mode 0
           // Serial.println("MESSAGE SENT");
            delay(500);
            return(0);
          }
        }
      }
      delay(500);
      Serial.flush();
      return(3);
    }
    break;
  case 6:  //enable motion detection
    {
      if(_replyMessageType == 0)
      {
        _replyMessageType = 1;
        strcpy(_replyBack,defaultSMSAddress);
      }
      if(_replyMessageType == 1)
      {
        Serial.print("AT+CMGS=\"");
        Serial.print(_replyBack);
        Serial.println("\"");
      }
      else
      {
        Serial.println("AT+CMGS=\"500\"");
      }
      
      timeOut = millis();
      while (millis() < timeOut + 2000)
      {
        if(Serial.available())
        {
          if(Serial.read() == '>')
          {
            ns = true;
            break;
          }
        }
      }
      if(!ns)
      {
        Serial.println(0x1B,BYTE); //do not send message
        delay(500);
        Serial.flush();
        return(1);
      } //There was an error waiting for the > 
      if(_replyMessageType == 2)
      {
        Serial.println(_replyBack);
      } 
      if(BMA180PRESENT)
      {
        Serial.println("Motion Detection Enabled");
        enableMotionDetection = 1;
      }
      else
      {
        Serial.println("Unable to Enable Motion Detection System");
      }
      Serial.println(0x1A,BYTE);
      uint8_t idx = 0;
      ns = false;
      timeOut = millis();
      while (millis() < timeOut + 60000)
      {
        if (Serial.available())
        {
          _rxBuffer[idx] = Serial.read();
          idx++;
          _rxBuffer[idx] = '\0';
          if(strstr(_rxBuffer,"ERROR")!= NULL)
          {
           // Serial.println("ERROR SENDING");
            delay(500);
            return(2);
          }
          if(strstr(_rxBuffer,"+CMGS:")!= NULL)
          {
           // Serial.println("MESSAGE SENT");
            delay(500);
            return(0);
          }
        }
      }
      delay(500);
      Serial.flush();
      return(3);
    }
    break;
  case 7:
    {
      if(_replyMessageType == 0)
      {
        _replyMessageType = 1;
        strcpy(_replyBack,defaultSMSAddress);
      }
      if(_replyMessageType == 1)
      {
        Serial.print("AT+CMGS=\"");
        Serial.print(_replyBack);
        Serial.println("\"");
      }
      else
      {
        Serial.println("AT+CMGS=\"500\"");
      }
      
      timeOut = millis();
      while (millis() < timeOut + 2000)
      {
        if(Serial.available())
        {
          if(Serial.read() == '>')
          {
            ns = true;
            break;
          }
        }
      }
      if(!ns)
      {
        Serial.println(0x1B,BYTE); //do not send message
        delay(500);
        Serial.flush();
        return(1);
      } //There was an error waiting for the > 
      if(_replyMessageType == 2)
      {
        Serial.println(_replyBack);
      } 
      Serial.println("Motion Detection Disabled");
      enableMotionDetection = 0;
      Serial.println(0x1A,BYTE);
      uint8_t idx = 0;
      ns = false;
      timeOut = millis();
      while (millis() < timeOut + 60000)
      {
        if (Serial.available())
        {
          _rxBuffer[idx] = Serial.read();
          idx++;
          _rxBuffer[idx] = '\0';
          if(strstr(_rxBuffer,"ERROR")!= NULL)
          {
           // Serial.println("ERROR SENDING");
            delay(500);
            return(2);
          }
          if(strstr(_rxBuffer,"+CMGS:")!= NULL)
          {
           // Serial.println("MESSAGE SENT");
            delay(500);
            return(0);
          }
        }
      }
      delay(500);
      Serial.flush();
      return(3);
    }
    break;
  case 8: 
    break;
  case 9:  //Command 9 will send a battery report
  {
      if(_replyMessageType == 0)
      {
        _replyMessageType = 1;
        strcpy(_replyBack,defaultSMSAddress);
      }
      if(_replyMessageType == 1)
      {
        Serial.print("AT+CMGS=\"");
        Serial.print(_replyBack);
        Serial.println("\"");
      }
      else
      {
        Serial.println("AT+CMGS=\"500\"");
      }
      
      timeOut = millis();
      while (millis() < timeOut + 2000)
      {
        if(Serial.available())
        {
          if(Serial.read() == '>')
          {
            ns = true;
            break;
          }
        }
      }
      if(!ns)
      {
        Serial.println(0x1B,BYTE); //do not send message
        delay(500);
        Serial.flush();
        return(1);
      } //There was an error waiting for the > 
      if(_replyMessageType == 2)
      {
        Serial.println(_replyBack);
      } 
      Serial.print(utcTime);
      Serial.print(",");
      Serial.println(date);
//      Serial.print("Battery Percent = ");				// NO SOC, just the voltage
//      Serial.println(getBatterySOC()/100.0,2);
      Serial.print("Battery Voltage = ");
      Serial.println(getBatteryVoltage()*0.00125,2);
      Serial.println(0x1A,BYTE);
      uint8_t idx = 0;
      ns = false;
      timeOut = millis();
      while (millis() < timeOut + 60000)
      {
        if (Serial.available())
        {
          _rxBuffer[idx] = Serial.read();
          idx++;
          _rxBuffer[idx] = '\0';
          if(strstr(_rxBuffer,"ERROR")!= NULL)
          {
           // Serial.println("ERROR SENDING");
            delay(500);
            return(2);
          }
          if(strstr(_rxBuffer,"+CMGS:")!= NULL)
          {
           // Serial.println("MESSAGE SENT");
            delay(500);
            return(0);
          }
        }
      }
      delay(500);
      Serial.flush();
      return(3);
    }
    break;
  case 99:  //Command 99 will send an alarm
  {
      if(_replyMessageType == 0)
      {
        _replyMessageType = 1;
        strcpy(_replyBack,defaultSMSAddress);
      }
      if(_replyMessageType == 1)
      {
        Serial.print("AT+CMGS=\"");
        Serial.print(_replyBack);
        Serial.println("\"");
      }
      else
      {
        Serial.println("AT+CMGS=\"500\"");
      }
      
      timeOut = millis();
      while (millis() < timeOut + 2000)
      {
        if(Serial.available())
        {
          if(Serial.read() == '>')
          {
            ns = true;
            break;
          }
        }
      }
      if(!ns)
      {
        Serial.println(0x1B,BYTE); //do not send message
        delay(500);
        Serial.flush();
        return(1);
      } //There was an error waiting for the > 
      if(_replyMessageType == 2)
      {
        Serial.println(_replyBack);
      } 
      Serial.print(utcTime);
      Serial.print(",");
      Serial.println(date);
      Serial.println("!!! SECURITY ALERT !!!");
    }
    break;
  default:
    Serial.flush();
    return(4);
  }
  Serial.print(googlePrefix);
  long httpLat = latitude/1000000;
  long httpLon = longitude/1000000;
  latitude = latitude - (httpLat*1000000);
  longitude = longitude - (httpLon*1000000);
  Serial.print(httpLat);
  Serial.print("+");
  Serial.print(latitude/10000.0,4);
  Serial.print(",");
  Serial.print(httpLon);
  Serial.print("+");
  Serial.print(abs(longitude/10000.0),4);
  Serial.print(displayTimeDate);
  Serial.print(utcTime);
  Serial.print(",");
  Serial.print(date);
  if(speedKPH/100 > 5)
  {
    Serial.print(",");
    Serial.print((speedKPH*KPH_TO_MPH),0);
    Serial.print(displayHeading);
    directionOfTravel(course,Heading);
    Serial.print(Heading);
  }
  Serial.println(googleSuffix);
  Serial.println(0x1A,BYTE);
  uint8_t idx = 0;
  ns = false;
  timeOut = millis();
  while (millis() < timeOut + 60000)
  {
    if (Serial.available()){
      _rxBuffer[idx] = Serial.read();
      idx++;
      _rxBuffer[idx] = '\0';
      if(strstr(_rxBuffer,"ERROR")!= NULL)
      {
       // Serial.println("ERROR SENDING");
        delay(500);
        Serial.flush();
        return(2);
      }
      if(strstr(_rxBuffer,"+CMGS:")!= NULL)
      {
       // Serial.println("MESSAGE SENT");
        delay(500);
        Serial.flush();
        return(0);
      }
    }
  }
  delay(500);
  Serial.flush();
  return(3);
}

void directionOfTravel(int _direction, char *_heading)
{
  if (_direction <= 2300 || _direction > 33800)
  {
    strcpy(_heading,"N");
  }
  if (_direction > 2300 && _direction <= 6800)
  {
    strcpy(_heading,"NE");
  }
  if (_direction > 6800 && _direction <= 11300)
  {
    strcpy(_heading,"E");
  }
  if (_direction > 11300 && _direction <= 15800)
  {
    strcpy(_heading,"SE");
  }
  if (_direction > 15800 && _direction <= 20300){
    strcpy(_heading,"S");
  }
  if (_direction > 20300 && _direction <= 24800)
  {
    strcpy(_heading,"SW");
  }
  if (_direction > 24800 && _direction <= 29300)
  {
    strcpy(_heading,"W");
  }
  if (_direction > 29300 && _direction <= 33800)
  {
    strcpy(_heading,"NW");
  }
}  

byte initializeBMA()
{
//  /*Set EEPROM image to write mode so we can change configuration*/
//  delay(20);
///*  if(I2c.read(BMA180,0x0D,1))
//  {
//    return(1);
//  } 
//  int ee_w = I2c.receive();
//  ee_w |= EE_W_MASK;
//  if(I2c.write(BMA180,0x0D,ee_w))
//  {
//    return(1);
//  }
//  delay(20);
//  /*Set mode configuration register to Mode 00*/
//  if(I2c.read(BMA180,0x30,1))
//  {
//    return(1);
//  }
//  int mode_config = I2c.receive();
//  mode_config &= ~(MODE_CONFIG_MASK);
//  if(I2c.write(BMA180,0x30,mode_config))
//  {
//    return(1);
//  }
//  delay(20);
//  /*Set bandwidth to 10Hz*/
//  if(I2c.read(BMA180,0x20,1))
//  {
//    return(1);
//  }
//  int bw = I2c.receive();
//  bw &= ~(BW_MASK);
//  bw |= 0x00 << 4;
//  if(I2c.write(BMA180,0x20,bw))
//  {
//    return(1);
//  }
//  delay(20);
//  /*Set acceleration to 8g*/
//  if(I2c.read(BMA180,0x35,1))
//  {
//    return(1);
//  }
//  int range = I2c.receive();
//  range &= ~(RANGE_MASK);
//  range |= 0x05 << 1 ;
//  if(I2c.write(BMA180,0x35,range))
//  {
//    return(1);
//  }
//  delay(20);
//  /*Set interrupt latch state*/
//  if(I2c.read(BMA180,0x21,1))
//  {
//    return(1);
//  }
//  int latch_int = I2c.receive();
//  latch_int &= ~(LAT_INT_MASK);
//  latch_int |= LAT_INT;
//  if(I2c.write(BMA180,0x21,latch_int))
//  {
//    return(1);
//  }
//  delay(20);
//  /*Set high g interrupt*/
//  if(I2c.read(BMA180,0x25,1))
//  {
//    return(1);
//  }
//  int high_low_info = I2c.receive();
//  high_low_info &= ~(0x30);
//  high_low_info |= 0x01 << 4;
//  if(I2c.write(BMA180,0x25,high_low_info))
//  {
//    return(1);
//  }
//  delay(20);
//  if(I2c.write(BMA180,0x2A,0x07))//high threshold setting...originally 0x0A
//  {
//    return(1);
//  }
//  delay(20);
//  if(I2c.read(BMA180,0x21,1))
//  {
//    return(1);
//  }  
//  int high_int = I2c.receive();
//  high_int &= ~(HIGH_INT_MASK);
//  high_int |= 0x01 << 5;
//  if(I2c.write(BMA180,0x21,high_int))
//  {
//    return(1);
//  }
  delay(20);  
  return(0);
}

uint8_t activateMotionDetection ()
{
//  enableMotionDetection = 0;
//  sendATCommand(CPOWD,rxBuffer,10,0,false);
//  delay(2000);
//  Serial.flush();
//  accelerometerState = 0;
//  if(I2c.read(BMA180,0x0D,1))
//  {
//    return(1);
//  }  
//  int reset_int = I2c.receive();
//  reset_int |= RESET_INT_MASK;
//  if(I2c.write(BMA180,0x0D,reset_int))
//  {
//    return(1);
//  }  
  delay(20);
  return(0);
}


