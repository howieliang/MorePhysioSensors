int HR_WINDOW = 10;
float[] dataIBI = new float[HR_WINDOW];
float[] dataIBI2 = new float[HR_WINDOW];

void initHR() {
  dataIBI = new float[HR_WINDOW];
  dataIBI2 = new float[HR_WINDOW];
}

float nextValueHR(float val, float[] HRArray) {
  float totalIBI = 0;
  appendArray(HRArray, val);
  for(int i = 0 ; i < HRArray.length; i++){
    totalIBI += HRArray[i];
  }
  return 60000./(totalIBI/(float)HR_WINDOW);
}
