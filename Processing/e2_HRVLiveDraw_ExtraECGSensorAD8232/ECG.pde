int ECG_WINDOW = 10;
float[] dataECG = new float[ECG_WINDOW];


void initECG() {
  dataECG = new float[ECG_WINDOW];
}

float nextValueECG(float v) {
  float totalECG = 0;
  appendArray(dataECG, v);
  for (int i = 0; i < dataECG.length; i++) {
    totalECG += dataECG[i];
  }
  return totalECG/ECG_WINDOW;
}
