# Chapter 2
## dev ไงที่ไม่ใช่ Helloworld
    ออกตัวก่อนว่าเพิ่งมีโอกาศใช้ kong และเนือ้งานจำเป็นต้องเขียน plugin เพิ่มเข้าไปเพราะว่า default ที่ให้มามันไม่ตอบโจทย์ คือ kong มันเป็น api gateway ไงแต่เนื้องานเราเอาไปคั่นหน้า web ละพอมัน error มันก็ไม่ควร return เป็น json กลับไปหง่ะ  มันควรตอบเป็นหน้า web เน๊อะ ก็เลยได้ลองเขียน plugin เองนี่หล่ะ

## เริ่มเลยดีกว่า
    ภาษาก่อนเลย kong ใช้ ภาษา lua ในการเขียน plugin และ มี SDK ชื่อ PDK (Plugin Development Kit)
เป็นตัวช่วยในการพัฒนา แบ่งเป็น 3 ส่วนหลัก ๆ
* โครงสร้าง project or file structure (พูดถึงใน Chapter ที่แล้วย้อนกลับไปดูอีกทีเรื่องการสร้าง  plugin)
* การ implement ตาม interface ที่ระบบออกแบบไว้
* การใช้ PDK ช่่วยสร้าง plugin

## การ implement ตาม interface ที่ระบบออกแบบไว้
    kong ออกแบบ file มาตรฐาน ที่เข้าไปคั่นการทำงานปกติ ไว้ให้เราสร้างเงื่อนไข หรือ feature แทรกเข้าไปได้ จะมี handler.lua ใช้ความคุมการทำงานหลักใน custom plugin
    และ schema.lua จะเป็นการสร้าง user interface ที่ใช้สำหรับทำ input
    เพื่อค่า configuration สำหรับ plugin ของเราโดยเฉพาะ ซึ่งจะอยู่ในรูปแบบ
    check box,radio box, text field, drop down list เป็นต้น
    ![image][schema-lua]
    อันนี้เป็นรูปหน้า config ของ plugin ที่ถููก install ที่ kong แล้วผ่าน Konga UI


    จากภาพข้างบน  ![image][route+plugin] ![image][service+plugin]
    ปกติเราจะใช้งาน plugin ร่วมกับ route และ service การเพิ่ม plugin สามารถ
    เพิ่มได้หลายตัว ต่อ 1 route หรือ  1 service ประมาณว่า plugin คือ feature
    เพราะฉะนั้น plugin ที่เราต้องการสร้างก็ีควรเป็น feature ที่ไม่ซ้ำกับที่มีอยู่แล่้ว  และ
    สามารถใช้ร่วมกับ plugin อื่น ๆได้ด้วย แล้วระบบจะรู้ลำดับความสำคัญของแต่ละ plugin
    ได้ยังไงหล่ะ ถ้าใส่ไปหลาย ๆ ตัวแล้วมันจะทำอันไหนก่อนไหนหลัง เด๊วเก็บไว้ตอนท้ายของส่วนนี้ละกัน


The current order of execution for the bundled plugins is:
![image][plugin-order]