import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";

const firebaseConfig = {
  apiKey: "AIzaSyCkjZvbKW7fRuSaqPTeJHBqbzTQLqzmYMU",
  authDomain: "career-setu-8ff5d.firebaseapp.com",
  projectId: "career-setu-8ff5d",
  storageBucket: "career-setu-8ff5d.firebasestorage.app",
  messagingSenderId: "693513638373",
  appId: "1:693513638373:web:72d014d58f6e3d60fa5f0c",
  measurementId: "G-KJ165CXNQR"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
