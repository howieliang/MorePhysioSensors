int ACC_WINDOW = 50;
PVector[] dataACC = new PVector[ACC_WINDOW];


void initACC() {
  dataACC = new PVector[ACC_WINDOW];
  for (int i = 0; i < dataACC.length; i++) {
    dataACC[i] = new PVector();
  }
}

void initCalib() {
  maxX = 0; 
  minX=1023; 
  bCalibed = false;
}

void testCalib(float x){
  if(x > maxX) maxX = x; 
  if(x < minX) minX = x; 
  println(maxX,minX);
}

PVector nextValueACC(PVector v) {
  PVector totalACC = new PVector();
  appendArray(dataACC, v);
  for (int i = 0; i < dataACC.length; i++) {
    totalACC = PVector.add(totalACC, dataACC[i]);
  }
  return PVector.div(totalACC, dataACC.length);
}
