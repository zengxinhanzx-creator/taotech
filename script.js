// 医疗AI网站交互功能
document.addEventListener('DOMContentLoaded', function() {
    const hamburger = document.querySelector('.hamburger');
    const navMenu = document.querySelector('.nav-menu');
    const navLinks = document.querySelectorAll('.nav-link');

    // 移动端菜单切换
    hamburger.addEventListener('click', function() {
        hamburger.classList.toggle('active');
        navMenu.classList.toggle('active');
    });

    // 点击导航链接时关闭移动端菜单
    navLinks.forEach(link => {
        link.addEventListener('click', function() {
            hamburger.classList.remove('active');
            navMenu.classList.remove('active');
        });
    });

    // 导航栏滚动效果
    window.addEventListener('scroll', function() {
        const navbar = document.querySelector('.navbar');
        if (window.scrollY > 100) {
            navbar.style.background = 'rgba(10, 10, 21, 0.95)';
            navbar.style.boxShadow = '0 4px 30px rgba(0, 0, 0, 0.4)';
            navbar.style.borderBottomColor = 'rgba(0, 245, 255, 0.3)';
        } else {
            navbar.style.background = 'rgba(10, 10, 21, 0.7)';
            navbar.style.boxShadow = '0 4px 30px rgba(0, 0, 0, 0.3)';
            navbar.style.borderBottomColor = 'rgba(0, 245, 255, 0.15)';
        }
    });

    // 平滑滚动到锚点
    navLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();
            const targetId = this.getAttribute('href');
            const targetSection = document.querySelector(targetId);
            
            if (targetSection) {
                const offsetTop = targetSection.offsetTop - 70; // 考虑导航栏高度
                window.scrollTo({
                    top: offsetTop,
                    behavior: 'smooth'
                });
            }
        });
    });

    // 增强滚动动画
    const observerOptions = {
        threshold: 0.15,
        rootMargin: '0px 0px -100px 0px'
    };

    const observer = new IntersectionObserver(function(entries) {
        entries.forEach((entry, index) => {
            if (entry.isIntersecting) {
                // 添加延迟动画
                setTimeout(() => {
                    if (entry.target.classList.contains('service-card')) {
                        entry.target.classList.add('scale-in');
                    } else if (entry.target.classList.contains('team-member')) {
                        entry.target.classList.add('fade-in-up');
                    } else if (entry.target.classList.contains('stat-item')) {
                        entry.target.classList.add('scale-in');
                    } else {
                        entry.target.classList.add('fade-in-up');
                    }
                }, index * 100);
                observer.unobserve(entry.target);
            }
        });
    }, observerOptions);

    // 观察需要动画的元素（排除team-member，因为它们已经有自己的动画）
    const animateElements = document.querySelectorAll('.service-card, .stat-item, .contact-item, .section-header, .about-text, .about-image, .tier-header');
    animateElements.forEach(el => {
        el.classList.add('animate-on-scroll');
        observer.observe(el);
    });
    
    // 团队成员单独处理，确保始终可见
    const teamMembers = document.querySelectorAll('.team-member');
    teamMembers.forEach(member => {
        member.style.opacity = '1';
        member.style.visibility = 'visible';
    });
    
    // 特殊动画：section-header
    const sectionHeaders = document.querySelectorAll('.section-header');
    sectionHeaders.forEach(header => {
        header.classList.add('animate-on-scroll');
        const headerObserver = new IntersectionObserver(function(entries) {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.remove('animate-on-scroll');
                    entry.target.classList.add('fade-in-up');
                }
            });
        }, { threshold: 0.3 });
        headerObserver.observe(header);
    });

    // 医疗AI数据计数动画
    function animateNumbers() {
        const statNumbers = document.querySelectorAll('.stat-item h4, .hero-stat .stat-number');
        
        statNumbers.forEach(stat => {
            const text = stat.textContent;
            const target = parseFloat(text.replace(/[^\d.]/g, ''));
            const suffix = text.replace(/[\d.]/g, '');
            let current = 0;
            const increment = target / 60;
            const timer = setInterval(() => {
                current += increment;
                if (current >= target) {
                    stat.textContent = target + suffix;
                    clearInterval(timer);
                } else {
                    if (text.includes('%')) {
                        stat.textContent = current.toFixed(1) + suffix;
                    } else if (text.includes('万')) {
                        stat.textContent = Math.floor(current) + '万' + suffix.replace('万', '');
                    } else {
                        stat.textContent = Math.floor(current) + suffix;
                    }
                }
            }, 25);
        });
    }

    // 当统计部分进入视口时开始计数动画
    const statsSection = document.querySelector('.stats');
    const statsObserver = new IntersectionObserver(function(entries) {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                animateNumbers();
                statsObserver.unobserve(entry.target);
            }
        });
    }, { threshold: 0.5 });

    if (statsSection) {
        statsObserver.observe(statsSection);
    }

    // 医疗AI演示预约表单处理
    const contactForm = document.querySelector('.contact-form form');
    if (contactForm) {
        contactForm.addEventListener('submit', async function(e) {
            e.preventDefault();
            
            console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            console.log('📤 前端：表单提交开始');
            
            // 获取表单数据 - 使用 name 属性（更可靠）
            const nameInput = this.querySelector('input[name="name"]');
            const emailInput = this.querySelector('input[name="email"]');
            const institutionInput = this.querySelector('input[name="institution"]');
            const serviceSelect = this.querySelector('select[name="service"]');
            const messageTextarea = this.querySelector('textarea[name="message"]');
            
            let name = nameInput ? nameInput.value.trim() : '';
            let email = emailInput ? emailInput.value.trim() : '';
            let institution = institutionInput ? institutionInput.value.trim() : '';
            const serviceValue = serviceSelect ? serviceSelect.value : '';
            const serviceText = serviceSelect && serviceSelect.selectedIndex > 0 
                ? serviceSelect.options[serviceSelect.selectedIndex].text 
                : serviceValue;
            let message = messageTextarea ? messageTextarea.value.trim() : '';
            
            // 备用方案：如果找不到，使用索引方式
            if (!name || !email || !institution) {
                console.warn('⚠ 使用备用方案获取表单数据');
                const inputs = this.querySelectorAll('input');
                if (inputs[0] && !name) name = inputs[0].value.trim();
                if (inputs[1] && !email) email = inputs[1].value.trim();
                if (inputs[2] && !institution) institution = inputs[2].value.trim();
                if (!message) {
                    const textarea = this.querySelector('textarea');
                    if (textarea) message = textarea.value.trim();
                }
            }
            
            console.log('  表单数据:');
            console.log(`    name: ${name}`);
            console.log(`    email: ${email}`);
            console.log(`    institution: ${institution}`);
            console.log(`    serviceValue: ${serviceValue}`);
            console.log(`    serviceText: ${serviceText}`);
            console.log(`    message: ${message ? message.substring(0, 50) + '...' : 'empty'}`);
            
            // 表单验证
            if (!name || !email || !institution || !serviceValue || !message) {
                console.warn('❌ 表单验证失败：必填字段为空');
                showNotification('請填寫所有必填字段', 'error');
                return;
            }
            
            if (!isValidEmail(email)) {
                console.warn('❌ 表单验证失败：邮箱格式错误');
                showNotification('請輸入有效的郵箱地址', 'error');
                return;
            }
            
            // 显示提交中状态
            const submitButton = this.querySelector('button[type="submit"]');
            const originalText = submitButton.innerHTML;
            submitButton.disabled = true;
            submitButton.innerHTML = '<i class="fas fa-spinner fa-spin"></i> 提交中...';
            
            // 准备提交数据
            const submitData = {
                name,
                email,
                institution,
                service: serviceText,
                message
            };
            
            console.log('  准备发送的数据:', JSON.stringify(submitData, null, 2));
            
            try {
                console.log('  发送请求到: /api/submit');
                
                // 发送到服务器
                const response = await fetch('/api/submit', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify(submitData)
                });
                
                console.log(`  响应状态: ${response.status} ${response.statusText}`);
                
                if (!response.ok) {
                    throw new Error(`HTTP error! status: ${response.status}`);
                }
                
                const data = await response.json();
                console.log('  服务器响应:', JSON.stringify(data, null, 2));
                
                if (data.success) {
                    console.log('✅ 提交成功');
                    showNotification(data.message || '臨床AI演示預約成功！我們的專家團隊將在24小時內與您聯繫，安排演示時間。', 'success');
                    this.reset();
                } else {
                    console.warn('❌ 提交失败:', data.message);
                    showNotification(data.message || '提交失敗，請稍後再試', 'error');
                }
            } catch (error) {
                console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                console.error('❌ 提交錯誤:');
                console.error(`  錯誤類型: ${error.name}`);
                console.error(`  錯誤消息: ${error.message}`);
                console.error(`  錯誤堆棧:`, error.stack);
                console.error('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
                showNotification('網絡錯誤，請檢查連接後重試', 'error');
            } finally {
                submitButton.disabled = false;
                submitButton.innerHTML = originalText;
                console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            }
        });
    } else {
        console.warn('⚠ 未找到表单元素: .contact-form form');
    }

    // 邮箱验证函数
    function isValidEmail(email) {
        const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
        return emailRegex.test(email);
    }

    // 通知函数
    function showNotification(message, type = 'info') {
        // 创建通知元素
        const notification = document.createElement('div');
        notification.className = `notification notification-${type}`;
        notification.textContent = message;
        
        // 添加样式
        notification.style.cssText = `
            position: fixed;
            top: 100px;
            right: 20px;
            background: ${type === 'success' ? '#10b981' : type === 'error' ? '#ef4444' : '#3b82f6'};
            color: white;
            padding: 15px 20px;
            border-radius: 8px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            z-index: 10000;
            transform: translateX(100%);
            transition: transform 0.3s ease;
            max-width: 300px;
            word-wrap: break-word;
        `;
        
        document.body.appendChild(notification);
        
        // 显示动画
        setTimeout(() => {
            notification.style.transform = 'translateX(0)';
        }, 100);
        
        // 自动隐藏
        setTimeout(() => {
            notification.style.transform = 'translateX(100%)';
            setTimeout(() => {
                document.body.removeChild(notification);
            }, 300);
        }, 3000);
    }

    // 服务卡片悬停效果增强
    const serviceCards = document.querySelectorAll('.service-card');
    serviceCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-10px) scale(1.02)';
        });
        
        card.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
        });
    });

    // 团队成员卡片悬停效果
    const teamMembers = document.querySelectorAll('.team-member');
    teamMembers.forEach(member => {
        member.addEventListener('mouseenter', function() {
            this.style.transform = 'translateY(-5px) scale(1.02)';
        });
        
        member.addEventListener('mouseleave', function() {
            this.style.transform = 'translateY(0) scale(1)';
        });
    });

    // 按钮点击波纹效果
    const buttons = document.querySelectorAll('.btn');
    buttons.forEach(button => {
        button.addEventListener('click', function(e) {
            const ripple = document.createElement('span');
            const rect = this.getBoundingClientRect();
            const size = Math.max(rect.width, rect.height);
            const x = e.clientX - rect.left - size / 2;
            const y = e.clientY - rect.top - size / 2;
            
            ripple.style.cssText = `
                position: absolute;
                width: ${size}px;
                height: ${size}px;
                left: ${x}px;
                top: ${y}px;
                background: rgba(255, 255, 255, 0.3);
                border-radius: 50%;
                transform: scale(0);
                animation: ripple 0.6s linear;
                pointer-events: none;
            `;
            
            this.style.position = 'relative';
            this.style.overflow = 'hidden';
            this.appendChild(ripple);
            
            setTimeout(() => {
                ripple.remove();
            }, 600);
        });
    });

    // 添加波纹动画CSS
    const style = document.createElement('style');
    style.textContent = `
        @keyframes ripple {
            to {
                transform: scale(4);
                opacity: 0;
            }
        }
    `;
    document.head.appendChild(style);

    // 页面加载完成后的初始化
    window.addEventListener('load', function() {
        // 添加页面加载完成的类
        document.body.classList.add('loaded');
        
        // 延迟显示动画元素
        setTimeout(() => {
            const heroContent = document.querySelector('.hero-content');
            if (heroContent) {
                heroContent.style.opacity = '1';
                heroContent.style.transform = 'translateY(0)';
            }
        }, 300);
        
        // 添加页面加载后的淡入效果
        const sections = document.querySelectorAll('section');
        sections.forEach((section, index) => {
            section.style.opacity = '0';
            section.style.transform = 'translateY(30px)';
            section.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
            
            setTimeout(() => {
                section.style.opacity = '1';
                section.style.transform = 'translateY(0)';
            }, 100 * (index + 1));
        });
    });

    // 键盘导航支持
    document.addEventListener('keydown', function(e) {
        if (e.key === 'Escape') {
            // 按ESC键关闭移动端菜单
            hamburger.classList.remove('active');
            navMenu.classList.remove('active');
        }
    });

    // 窗口大小改变时的处理
    window.addEventListener('resize', function() {
        if (window.innerWidth > 768) {
            hamburger.classList.remove('active');
            navMenu.classList.remove('active');
        }
    });
});

// 添加一些额外的交互效果
document.addEventListener('DOMContentLoaded', function() {
    // 鼠标跟随效果（可选）
    let mouseX = 0, mouseY = 0;
    let ballX = 0, ballY = 0;
    const speed = 0.1;

    document.addEventListener('mousemove', function(e) {
        mouseX = e.clientX;
        mouseY = e.clientY;
    });

    function animate() {
        ballX += (mouseX - ballX) * speed;
        ballY += (mouseY - ballY) * speed;
        requestAnimationFrame(animate);
    }
    animate();

    // 医疗AI可视化交互效果
    const aiBrain = document.querySelector('.ai-brain');
    if (aiBrain) {
        aiBrain.addEventListener('click', function() {
            this.style.animation = 'none';
            setTimeout(() => {
                this.style.animation = 'brainPulse 2s ease-in-out infinite';
            }, 10);
        });
    }

    // 数据点点击效果
    const dataPoints = document.querySelectorAll('.data-point');
    dataPoints.forEach(point => {
        point.addEventListener('click', function() {
            this.style.background = '#00d4ff';
            this.style.boxShadow = '0 0 20px #00d4ff';
            setTimeout(() => {
                this.style.background = '#ff6b6b';
                this.style.boxShadow = 'none';
            }, 1000);
        });
    });

    // 网格细胞交互效果
    const gridCells = document.querySelectorAll('.grid-cell');
    gridCells.forEach(cell => {
        cell.addEventListener('mouseenter', function() {
            this.style.background = 'linear-gradient(135deg, #00d4ff 0%, #0099cc 100%)';
            this.style.transform = 'scale(1.1)';
        });
        
        cell.addEventListener('mouseleave', function() {
            if (!this.classList.contains('active')) {
                this.style.background = 'rgba(0, 212, 255, 0.1)';
            }
            this.style.transform = 'scale(1)';
        });
    });

    // 服务卡片特殊效果
    const serviceCards = document.querySelectorAll('.service-card');
    serviceCards.forEach(card => {
        card.addEventListener('mouseenter', function() {
            const icon = this.querySelector('.service-icon');
            icon.style.transform = 'scale(1.1) rotate(5deg)';
            icon.style.boxShadow = '0 10px 30px rgba(0, 212, 255, 0.4)';
        });
        
        card.addEventListener('mouseleave', function() {
            const icon = this.querySelector('.service-icon');
            icon.style.transform = 'scale(1) rotate(0deg)';
            icon.style.boxShadow = 'none';
        });
    });

    // 团队成员卡片悬停效果增强
    const teamMembers = document.querySelectorAll('.team-member');
    teamMembers.forEach(member => {
        member.addEventListener('mouseenter', function() {
            const avatar = this.querySelector('.member-avatar');
            avatar.style.transform = 'scale(1.05)';
            avatar.style.boxShadow = '0 10px 30px rgba(0, 212, 255, 0.3)';
        });
        
        member.addEventListener('mouseleave', function() {
            const avatar = this.querySelector('.member-avatar');
            avatar.style.transform = 'scale(1)';
            avatar.style.boxShadow = 'none';
        });
    });

    // 技术亮点交互
    const techItems = document.querySelectorAll('.tech-item');
    techItems.forEach(item => {
        item.addEventListener('click', function() {
            this.style.background = 'linear-gradient(135deg, #00d4ff 0%, #0099cc 100%)';
            this.style.color = 'white';
            setTimeout(() => {
                this.style.background = 'rgba(0, 212, 255, 0.1)';
                this.style.color = '#00d4ff';
            }, 2000);
        });
    });

    // 特征标签悬停效果
    const featureTags = document.querySelectorAll('.feature-tag');
    featureTags.forEach(tag => {
        tag.addEventListener('mouseenter', function() {
            this.style.background = 'rgba(0, 212, 255, 0.2)';
            this.style.transform = 'scale(1.05)';
        });
        
        tag.addEventListener('mouseleave', function() {
            this.style.background = 'rgba(0, 212, 255, 0.1)';
            this.style.transform = 'scale(1)';
        });
    });

    // 专家技能标签效果
    const expertiseTags = document.querySelectorAll('.expertise-tag');
    expertiseTags.forEach(tag => {
        tag.addEventListener('click', function() {
            this.style.background = 'linear-gradient(135deg, #ff6b6b 0%, #ee5a24 100%)';
            this.style.color = 'white';
            setTimeout(() => {
                this.style.background = 'rgba(255, 107, 107, 0.1)';
                this.style.color = '#ff6b6b';
            }, 1500);
        });
    });

    // 添加医疗AI主题的粒子效果
    function createParticles() {
        const hero = document.querySelector('.hero');
        if (!hero) return;
        
        for (let i = 0; i < 20; i++) {
            const particle = document.createElement('div');
            particle.className = 'particle';
            particle.style.cssText = `
                position: absolute;
                width: 2px;
                height: 2px;
                background: #00d4ff;
                border-radius: 50%;
                pointer-events: none;
                animation: particleFloat ${3 + Math.random() * 4}s linear infinite;
                left: ${Math.random() * 100}%;
                top: ${Math.random() * 100}%;
                animation-delay: ${Math.random() * 2}s;
            `;
            hero.appendChild(particle);
        }
    }

    // 添加粒子动画CSS
    const particleStyle = document.createElement('style');
    particleStyle.textContent = `
        @keyframes particleFloat {
            0% {
                transform: translateY(100vh) translateX(0);
                opacity: 0;
            }
            10% {
                opacity: 1;
            }
            90% {
                opacity: 1;
            }
            100% {
                transform: translateY(-100px) translateX(${Math.random() * 200 - 100}px);
                opacity: 0;
            }
        }
    `;
    document.head.appendChild(particleStyle);

    // 创建粒子效果
    createParticles();

    // 添加医疗数据流动效果
    function createDataFlow() {
        const aboutSection = document.querySelector('.about');
        if (!aboutSection) return;
        
        const dataFlow = document.createElement('div');
        dataFlow.className = 'data-flow';
        dataFlow.style.cssText = `
            position: absolute;
            top: 0;
            left: 0;
            width: 100%;
            height: 100%;
            pointer-events: none;
            overflow: hidden;
        `;
        
        for (let i = 0; i < 5; i++) {
            const flow = document.createElement('div');
            flow.style.cssText = `
                position: absolute;
                width: 1px;
                height: 100px;
                background: linear-gradient(to bottom, transparent, #00d4ff, transparent);
                left: ${Math.random() * 100}%;
                animation: dataFlowMove ${4 + Math.random() * 3}s linear infinite;
                animation-delay: ${Math.random() * 2}s;
            `;
            dataFlow.appendChild(flow);
        }
        
        aboutSection.style.position = 'relative';
        aboutSection.appendChild(dataFlow);
    }

    // 添加数据流动动画CSS
    const dataFlowStyle = document.createElement('style');
    dataFlowStyle.textContent = `
        @keyframes dataFlowMove {
            0% {
                top: -100px;
                opacity: 0;
            }
            50% {
                opacity: 1;
            }
            100% {
                top: 100%;
                opacity: 0;
            }
        }
    `;
    document.head.appendChild(dataFlowStyle);

    // 创建数据流动效果
    createDataFlow();
});
